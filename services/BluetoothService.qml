pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import "../helpers/bluetooth-utils.js" as BluetoothUtils
import qs.common
import qs.services

Singleton {
  id: root

  // Constants (centralized tunables)
  readonly property int ctlPollMs: 1500
  readonly property int ctlPollSoonMs: 250
  readonly property int scanAutoStopMs: 6000

  property bool airplaneModeToggled: false
  property bool lastBluetoothBlocked: false
  property bool lastWifiBlocked: false
  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter

  // Power/blocked state
  readonly property bool enabled: adapter ? adapter.enabled : root.ctlPowered
  readonly property bool blocked: adapter?.state === BluetoothAdapterState.Blocked
  property bool ctlPowered: false
  property bool ctlDiscovering: false
  property bool ctlDiscoverable: false
  // Adapter discoverability (advertising) flag (driven by bluetoothctl)
  readonly property bool discoverable: root.ctlDiscoverable
  readonly property var devices: adapter ? adapter.devices : null
  readonly property var connectedDevices: {
    if (!adapter || !adapter.devices) {
      return [];
    }
    return adapter.devices.values.filter(function (dev) {
      return dev && dev.connected;
    });
  }

  // Experimental: best‑effort RSSI polling for connected devices (without root)
  // Enabled in debug mode or via user setting in Settings > Network
  property bool rssiPollingEnabled: Settings.network.bluetoothRssiPollingEnabled ? true : false
  // Interval can be configured from Settings; defaults to 10s
  property int rssiPollIntervalMs: Settings.network.bluetoothRssiPollIntervalMs
  // RSSI helper sub‑component
  property BluetoothRssi rssi: BluetoothRssi {
    enabled: root.enabled && root.rssiPollingEnabled
    intervalMs: root.rssiPollIntervalMs
    connectedDevices: root.connectedDevices
  }

  // Tunables for CLI pairing/connect flow
  property int pairWaitSeconds: 20
  property int connectAttempts: 5
  property int connectRetryIntervalMs: 2000

  // Internal: temporarily pause discovery during pair/connect to reduce HCI churn
  // Use a resume deadline to coalesce overlapping pauses safely
  property bool _discoveryWasRunning: false
  property double _discoveryResumeAtMs: 0
  // Timer used to restore discovery after temporary pause during pair/connect
  Timer {
    id: restoreDiscoveryTimer
    repeat: false
    onTriggered: {
      const now = Date.now();
      if (now < root._discoveryResumeAtMs) {
        // Not yet time to resume; reschedule
        interval = Math.max(100, root._discoveryResumeAtMs - now);
        restart();
        return;
      }
      if (root._discoveryWasRunning) {
        root.setScanActive(true, 0);
      }
      root._discoveryWasRunning = false;
      root._discoveryResumeAtMs = 0;
    }
  }

  function _pauseDiscoveryFor(ms) {
    try {
      // Remember if discovery was running before the first pause
      root._discoveryWasRunning = root._discoveryWasRunning || !!root.ctlDiscovering;
      if (root.ctlDiscovering) {
        root.setScanActive(false, 0);
      }
      if (ms && ms > 0) {
        const now = Date.now();
        const resumeAt = now + ms;
        if (resumeAt > root._discoveryResumeAtMs) {
          root._discoveryResumeAtMs = resumeAt;
        }
        restoreDiscoveryTimer.interval = Math.max(100, root._discoveryResumeAtMs - now);
        restoreDiscoveryTimer.restart();
      }
    } catch (_) {}
  }

  // Persistent process for fallback scanning to keep the session alive
  Process {
    id: fallbackScanProcess
    // Pipe scan on and a long sleep to bluetoothctl to keep it running
    command: ["sh", "-c", "(echo 'scan on'; sleep 3600) | bluetoothctl"]
  }

  // Unify discovery controls and auto‑stop window
  function setScanActive(active, durationMs) {
    // Cancel any scheduled resume so manual toggle wins
    try {
      root._discoveryResumeAtMs = 0;
      restoreDiscoveryTimer.stop();
      root._discoveryWasRunning = false;
    } catch (_) {}

    // Prefer Quickshell API if available, fall back to bluetoothctl
    var nativeSuccess = false;
    try {
      if (adapter) {
        if (active && adapter.startDiscovery !== undefined) {
          adapter.startDiscovery();
          nativeSuccess = true;
        } else if (!active && adapter.stopDiscovery !== undefined) {
          adapter.stopDiscovery();
          nativeSuccess = true;
        }
      } else {}
    } catch (e1) {}

    // Only issue bluetoothctl if we didn't use the adapter API
    if (!nativeSuccess) {
      if (active) {
        fallbackScanProcess.running = true;
      } else {
        fallbackScanProcess.running = false;
        // Explicitly send scan off command as well to ensure state is cleared
        btExec(["bluetoothctl", "scan", "off"]);
      }
    } else {
      // Ensure fallback process is stopped if we switched to native
      if (fallbackScanProcess.running) {
        fallbackScanProcess.running = false;
      }
    }

    if (active && durationMs && durationMs > 0) {
      manualScanTimer.interval = durationMs;
      manualScanTimer.restart();
    } else {
      if (manualScanTimer.running) {
        manualScanTimer.stop();
      }
    }
    requestCtlPoll(ctlPollSoonMs);
  }

  // Explicit toggle that cancels any pending restore so UI button behaves predictably
  function toggleDiscovery() {
    if (!adapter) {
      return;
    }
    setScanActive(!root.scanningActive, scanAutoStopMs);
  }

  // Auto-stop manual discovery after a short window
  Timer {
    id: manualScanTimer
    repeat: false
    onTriggered: {
      // Stop scan if currently active
      if (root.scanningActive) {
        root.setScanActive(false, 0);
      } else {}
    }
  }

  // Exposed scanning flag for UI button state; reflects adapter discovery when available
  readonly property bool scanningActive: ((adapter && adapter.discovering) ? true : (root.ctlDiscovering === true)) || manualScanTimer.running

  function init() {
  }

  Component.onCompleted: {
    // Prime state immediately so UI reflects correct power/discovery flags
    pollCtlState();
  }

  // Note: We intentionally avoid creating or managing a custom BlueZ agent in-process.
  // Pairing flows are delegated to `bluetoothctl` as needed to keep behavior
  // consistent and reduce maintenance complexity.

  // No implicit discovery auto-start; state polled from bluetoothctl instead

  // Track adapter state changes
  Connections {
    target: adapter
    function onStateChanged() {
      if (!adapter) {
        return;
      }
      if (adapter.state === BluetoothAdapter.Enabling || adapter.state === BluetoothAdapter.Disabling) {
        return;
      }
      const bluetoothBlockedToggled = (root.blocked !== lastBluetoothBlocked);
      root.lastBluetoothBlocked = root.blocked;
      if (bluetoothBlockedToggled) {
        checkWifiBlocked.running = true;
      } else if (adapter.state === BluetoothAdapter.Enabled) {} else if (adapter.state === BluetoothAdapter.Disabled) {}
    }
  }

  Process {
    id: checkWifiBlocked
    running: false
    command: ["rfkill", "list", "wifi"]
    stdout: StdioCollector {
      onStreamFinished: {
        var wifiBlocked = text && text.trim().indexOf("Soft blocked: yes") !== -1;
        // Check if airplane mode has been toggled
        if (wifiBlocked && root.blocked) {
          root.airplaneModeToggled = true;
          root.lastWifiBlocked = true;
          NetworkService.setWifiEnabled(false);
        } else if (!wifiBlocked && lastWifiBlocked) {
          root.airplaneModeToggled = true;
          root.lastWifiBlocked = false;
          NetworkService.setWifiEnabled(true);
        } else if (adapter.enabled) {} else {}
        root.airplaneModeToggled = false;
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text && text.trim()) {}
      }
    }
  }

  // bluetoothctl state polling
  Process {
    id: ctlShowProcess
    running: false
    stdout: StdioCollector {
      id: ctlStdout
    }
    onExited: function (exitCode, exitStatus) {
      try {
        var text = ctlStdout.text || "";
        // Parse Powered/Discoverable/Discovering lines
        var mp = text.match(/\bPowered:\s*(yes|no)\b/i);
        if (mp && mp.length > 1) {
          root.ctlPowered = (mp[1].toLowerCase() === "yes");
        }
        var md = text.match(/\bDiscoverable:\s*(yes|no)\b/i);
        if (md && md.length > 1) {
          root.ctlDiscoverable = (md[1].toLowerCase() === "yes");
        }
        var ms = text.match(/\bDiscovering:\s*(yes|no)\b/i);
        if (ms && ms.length > 1) {
          var discovering = (ms[1].toLowerCase() === "yes");
          root.ctlDiscovering = discovering;
        }
      } catch (e) {}
    }
  }

  function pollCtlState() {
    if (ctlShowProcess.running) {
      return;
    }
    try {
      ctlShowProcess.command = ["bluetoothctl", "show"];
      ctlShowProcess.running = true;
    } catch (_) {}
  }

  // Periodic state polling
  Timer {
    id: ctlPollTimer
    interval: ctlPollMs
    repeat: true
    running: root.enabled
    onTriggered: pollCtlState()
  }

  // Short-delay poll scheduler
  Timer {
    id: pollCtlStateSoonTimer
    interval: ctlPollSoonMs
    repeat: false
    onTriggered: pollCtlState()
  }

  function requestCtlPoll(delayMs) {
    pollCtlStateSoonTimer.interval = Math.max(50, delayMs || ctlPollSoonMs);
    pollCtlStateSoonTimer.restart();
  }

  // Adapter power (enable/disable) via bluetoothctl
  function setBluetoothEnabled(state) {
    try {
      btExec(["bluetoothctl", "power", state ? "on" : "off"]);
      root.ctlPowered = !!state;
      requestCtlPoll(ctlPollSoonMs);
    } catch (e) {}
  }

  // Toggle adapter discoverability (advertising visibility) via bluetoothctl
  function setDiscoverable(state) {
    try {
      btExec(["bluetoothctl", "discoverable", state ? "on" : "off"]);
      root.ctlDiscoverable = !!state; // optimistic
      requestCtlPoll(ctlPollSoonMs);
      if (state) {} else {}
    } catch (e) {}
  }

  function sortDevices(devices) {
    return devices.sort(function (a, b) {
      var aName = a.name || a.deviceName || "";
      var bName = b.name || b.deviceName || "";

      var aHasRealName = aName.indexOf(" ") !== -1 && aName.length > 3;
      var bHasRealName = bName.indexOf(" ") !== -1 && bName.length > 3;

      if (aHasRealName && !bHasRealName) {
        return -1;
      }
      if (!aHasRealName && bHasRealName) {
        return 1;
      }

      var aSignal = (a.signalStrength !== undefined && a.signalStrength > 0) ? a.signalStrength : 0;
      var bSignal = (b.signalStrength !== undefined && b.signalStrength > 0) ? b.signalStrength : 0;
      return bSignal - aSignal;
    });
  }

  function getDeviceIcon(device) {
    if (!device) {
      return "bt-device-generic";
    }
    return BluetoothUtils.deviceIcon(device.name || device.deviceName, device.icon);
  }

  function canConnect(device) {
    if (!device) {
      return false;
    }

    /*
    Paired
    Means you’ve successfully exchanged keys with the device.
    The devices remember each other and can authenticate without repeating the pairing process.
    Example: once your headphones are paired, you don’t need to type a PIN every time.
    Hence, instead of !device.paired, should be device.connected
    */
    // Only allow connect if device is already paired or trusted
    return !device.connected && (device.paired || device.trusted) && !device.pairing && !device.blocked;
  }

  function canDisconnect(device) {
    if (!device) {
      return false;
    }
    return device.connected && !device.pairing && !device.blocked;
  }
  // Status string for a device (translated)
  function getStatusString(device) {
    if (!device) {
      return "";
    }
    try {
      if (device.pairing)
        return "Pairing";
      if (device.blocked)
        return "Blocked";
      if (device.state === BluetoothDevice.Connecting)
        return "Connecting";
      if (device.state === BluetoothDevice.Disconnecting)
        return "Disconnecting";
    } catch (_) {}
    return "";
  }

  // Textual signal quality (translated)
  function getSignalStrength(device) {
    var p = getSignalPercent(device);
    if (p === null)
      return "Unknown";
    if (p >= 80)
      return "Excellent";
    if (p >= 60)
      return "Good";
    if (p >= 40)
      return "Fair";
    if (p >= 20)
      return "Poor";
    return "Very poor";
  }

  // Numeric helpers for UI rendering
  function getSignalPercent(device) {
    // Establish binding dependency so UI updates when RSSI cache changes
    var _v = rssi.version;
    return BluetoothUtils.signalPercent(device, rssi.cache, _v);
  }

  function getBatteryPercent(device) {
    return BluetoothUtils.batteryPercent(device);
  }

  function getSignalIcon(device) {
    var p = getSignalPercent(device);
    return BluetoothUtils.signalIcon(p);
  }

  function isDeviceBusy(device) {
    if (!device) {
      return false;
    }

    return device.pairing || device.state === BluetoothDevice.Disconnecting || device.state === BluetoothDevice.Connecting;
  }

  // Return a stable unique key for a device (prefer MAC address)
  function deviceKey(device) {
    return BluetoothUtils.deviceKey(device);
  }

  // Deduplicate a list of devices using the stable key
  function dedupeDevices(devList) {
    return BluetoothUtils.dedupeDevices(devList);
  }

  // Separate capability helpers
  function canPair(device) {
    if (!device) {
      return false;
    }
    return !device.connected && !device.paired && !device.trusted && !device.pairing && !device.blocked;
  }

  // Pairing and unpairing helpers
  function pairDevice(device) {
    if (!device) {
      return;
    }
    // Delegate pairing to bluetoothctl which registers/uses its own agent
    try {
      pairWithBluetoothctl(device);
    } catch (e) {}
  }

  // Interaction state
  property bool pinRequired: false

  function submitPin(pin) {
    if (pairingProcess.running) {
      pairingProcess.write(pin + "\n");
      root.pinRequired = false;
    }
  }

  function cancelPairing() {
    if (pairingProcess.running) {
      pairingProcess.kill();
    }
    root.pinRequired = false;
  }

  // Interactive pairing process
  Process {
    id: pairingProcess
    stdout: SplitParser {
      onRead: data => {
        var chunk = data;
        if (chunk.indexOf("[PIN_REQ]") !== -1) {
          root.pinRequired = true;
        }
      }
    }
    stderr: StdioCollector {}
    onExited: {
      root.pinRequired = false;
      // Restore discovery if we paused it
      if (root._discoveryWasRunning) {
        root.setScanActive(true, 0);
      }
      root._discoveryWasRunning = false;
    }
  }

  // Pair using bluetoothctl which registers its own BlueZ agent internally.
  function pairWithBluetoothctl(device) {
    if (!device) {
      return;
    }
    var addr = BluetoothUtils.macFromDevice(device);
    if (!addr || addr.length < 7) {
      return;
    }

    // Stop any previous pairing attempt
    if (pairingProcess.running) {
      pairingProcess.kill();
    }
    root.pinRequired = false;

    // Compute bounded waits from tunables
    const pairWait = Math.max(5, Number(root.pairWaitSeconds) | 0);
    const attempts = Math.max(1, Number(root.connectAttempts) | 0);
    const intervalMs = Math.max(500, Number(root.connectRetryIntervalMs) | 0);
    const intervalSec = Math.max(1, Math.round(intervalMs / 1000));

    // Pause discovery during pair/connect to avoid interference
    const totalPauseMs = (pairWait * 1000) + (attempts * intervalSec * 1000) + 2000;
    _pauseDiscoveryFor(totalPauseMs);

    const scriptPath = Quickshell.shellDir + "/Scripts/python/src/network/bluetooth-connect.py";

    pairingProcess.command = ["python3", scriptPath, String(addr), String(pairWait), String(attempts), String(intervalSec)];
    pairingProcess.running = true;
  }

  // Helper to run bluetoothctl and scripts with consistent error logging
  function btExec(args) {
    try {
      Quickshell.execDetached(args);
    } catch (e) {}
  }

  // Status key for a device (untranslated)
  function getStatusKey(device) {
    if (!device) {
      return "";
    }
    try {
      if (device.pairing)
        return "pairing";
      if (device.blocked)
        return "blocked";
      if (device.state === BluetoothDevice.Connecting)
        return "connecting";
      if (device.state === BluetoothDevice.Disconnecting)
        return "disconnecting";
    } catch (_) {}
    return "";
  }

  function unpairDevice(device) {
    // Alias to forgetDevice for clarity in UI
    forgetDevice(device);
  }

  function connectDeviceWithTrust(device) {
    if (!device) {
      return;
    }
    try {
      device.trusted = true;
      device.connect();
    } catch (e) {}
  }

  function disconnectDevice(device) {
    if (!device) {
      return;
    }
    try {
      device.disconnect();
    } catch (e) {}
  }

  function forgetDevice(device) {
    if (!device) {
      return;
    }
    try {
      device.trusted = false;
      device.forget();
    } catch (e) {}
  }
}
