pragma Singleton

import QtQml
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import "../helpers/bluetooth-utils.js" as BluetoothUtils
import qs.common
import qs.services

QtObject {
  id: root

  readonly property int ctlPollMs: 1500
  readonly property int ctlPollSoonMs: 250
  readonly property int scanAutoStopMs: 6000

  property bool airplaneModeToggled: false
  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter

  property bool enabled: false
  property bool ctlPowered: false
  property bool ctlDiscovering: false
  property bool ctlDiscoverable: false
  readonly property bool discoverable: root.ctlDiscoverable

  readonly property var devices: adapter ? adapter.devices : null

  readonly property var connectedDevices: {
    if (!adapter || !adapter.devices)
      return [];
    return adapter.devices.values.filter(function (dev) {
      return dev && dev.connected;
    });
  }

  property bool rssiPollingEnabled: Settings && Settings.network ? !!Settings.network.bluetoothRssiPollingEnabled : false

  property int rssiPollIntervalMs: Settings && Settings.network && Settings.network.bluetoothRssiPollIntervalMs ? Settings.network.bluetoothRssiPollIntervalMs : 10000

  property BluetoothRssi rssi: BluetoothRssi {
    enabled: root.enabled && root.rssiPollingEnabled
    intervalMs: root.rssiPollIntervalMs
    connectedDevices: root.connectedDevices
  }

  property int pairWaitSeconds: 20
  property int connectAttempts: 5
  property int connectRetryIntervalMs: 2000

  property bool _discoveryWasRunning: false
  property double _discoveryResumeAtMs: 0

  property Timer restoreDiscoveryTimer: Timer {
    repeat: false
    onTriggered: {
      const now = Date.now();
      if (now < root._discoveryResumeAtMs) {
        interval = Math.max(100, root._discoveryResumeAtMs - now);
        restart();
        return;
      }
      if (root._discoveryWasRunning)
        root.setScanActive(true, 0);
      root._discoveryWasRunning = false;
      root._discoveryResumeAtMs = 0;
    }
  }

  function _pauseDiscoveryFor(ms) {
    try {
      root._discoveryWasRunning = root._discoveryWasRunning || !!root.ctlDiscovering;

      if (root.ctlDiscovering)
        root.setScanActive(false, 0);

      if (ms && ms > 0) {
        const now = Date.now();
        const resumeAt = now + ms;
        if (resumeAt > root._discoveryResumeAtMs)
          root._discoveryResumeAtMs = resumeAt;
        restoreDiscoveryTimer.interval = Math.max(100, root._discoveryResumeAtMs - now);
        restoreDiscoveryTimer.restart();
      }
    } catch (_) {}
  }

  property Process fallbackScanProcess: Process {
    command: ["sh", "-c", "(echo 'scan on'; sleep 3600) | bluetoothctl"]
  }

  function setScanActive(active, durationMs) {
    try {
      root._discoveryResumeAtMs = 0;
      restoreDiscoveryTimer.stop();
      root._discoveryWasRunning = false;
    } catch (_) {}

    let nativeSuccess = false;

    try {
      if (adapter) {
        if (active && adapter.startDiscovery !== undefined) {
          adapter.startDiscovery();
          nativeSuccess = true;
        } else if (!active && adapter.stopDiscovery !== undefined) {
          adapter.stopDiscovery();
          nativeSuccess = true;
        }
      }
    } catch (_) {}

    if (!nativeSuccess) {
      fallbackScanProcess.running = active;
      if (!active)
        btExec(["bluetoothctl", "scan", "off"]);
    } else if (fallbackScanProcess.running) {
      fallbackScanProcess.running = false;
    }

    if (active && durationMs > 0) {
      manualScanTimer.interval = durationMs;
      manualScanTimer.restart();
    } else {
      manualScanTimer.stop();
    }

    requestCtlPoll(ctlPollSoonMs);
  }

  function toggleDiscovery() {
    if (!adapter)
      return;
    setScanActive(!root.scanningActive, scanAutoStopMs);
  }

  property Timer manualScanTimer: Timer {
    repeat: false
    onTriggered: {
      if (root.scanningActive)
        root.setScanActive(false, 0);
    }
  }

  readonly property bool scanningActive: ((adapter && adapter.discovering) ? true : root.ctlDiscovering) || manualScanTimer.running

  Component.onCompleted: pollCtlState()

  property Connections adapterConnections: Connections {
    target: adapter
    function onStateChanged() {
    }
  }

  property Process ctlShowProcess: Process {
    id: ctlProc
    stdout: StdioCollector {
      id: ctlStdout
    }
    onExited: {
      try {
        const text = ctlStdout.text || "";

        const mp = text.match(/\bPowered:\s*(yes|no)\b/i);
        if (mp) {
          root.ctlPowered = mp[1].toLowerCase() === "yes";
          root.enabled = root.ctlPowered;
        }

        const md = text.match(/\bDiscoverable:\s*(yes|no)\b/i);
        if (md)
          root.ctlDiscoverable = md[1].toLowerCase() === "yes";

        const ms = text.match(/\bDiscovering:\s*(yes|no)\b/i);
        if (ms)
          root.ctlDiscovering = ms[1].toLowerCase() === "yes";
      } catch (_) {}
    }
  }

  function pollCtlState() {
    if (ctlProc.running)
      return;
    ctlProc.command = ["bluetoothctl", "show"];
    ctlProc.running = true;
  }

  property Timer ctlPollTimer: Timer {
    interval: ctlPollMs
    repeat: true
    running: root.enabled
    onTriggered: pollCtlState()
  }

  property Timer pollCtlStateSoonTimer: Timer {
    interval: ctlPollSoonMs
    repeat: false
    onTriggered: pollCtlState()
  }

  function requestCtlPoll(delayMs) {
    pollCtlStateSoonTimer.interval = Math.max(50, delayMs || ctlPollSoonMs);
    pollCtlStateSoonTimer.restart();
  }

  function setBluetoothEnabled(state) {
    btExec(["bluetoothctl", "power", state ? "on" : "off"]);
    root.ctlPowered = !!state;
    root.enabled = root.ctlPowered;
    requestCtlPoll(ctlPollSoonMs);
  }

  function setDiscoverable(state) {
    btExec(["bluetoothctl", "discoverable", state ? "on" : "off"]);
    root.ctlDiscoverable = !!state;
    requestCtlPoll(ctlPollSoonMs);
  }

  function getSignalPercent(device) {
    const _v = rssi.version;
    return BluetoothUtils.signalPercent(device, rssi.cache, _v);
  }

  function getBatteryPercent(device) {
    return BluetoothUtils.batteryPercent(device);
  }

  function deviceKey(device) {
    return BluetoothUtils.deviceKey(device);
  }

  function dedupeDevices(list) {
    return BluetoothUtils.dedupeDevices(list);
  }

  function canConnect(device) {
    return !!device && !device.connected && (device.paired || device.trusted) && !device.pairing && !device.blocked;
  }

  function canDisconnect(device) {
    return !!device && device.connected && !device.pairing && !device.blocked;
  }

  function isDeviceBusy(device) {
    return !!device && (device.pairing || device.state === BluetoothDevice.Connecting || device.state === BluetoothDevice.Disconnecting);
  }

  function getStatusKey(device) {
    if (!device)
      return "";
    if (device.pairing)
      return "pairing";
    if (device.blocked)
      return "blocked";
    if (device.state === BluetoothDevice.Connecting)
      return "connecting";
    if (device.state === BluetoothDevice.Disconnecting)
      return "disconnecting";
    return "";
  }

  function pairDevice(device) {
    if (!device)
      return;
    pairWithBluetoothctl(device);
  }

  function pairWithBluetoothctl(device) {
    const addr = BluetoothUtils.macFromDevice(device);
    if (!addr || addr.length < 7)
      return;

    const pairWait = Math.max(5, root.pairWaitSeconds | 0);
    const attempts = Math.max(1, root.connectAttempts | 0);
    const intervalMs = Math.max(500, root.connectRetryIntervalMs | 0);
    const intervalSec = Math.max(1, Math.round(intervalMs / 1000));

    _pauseDiscoveryFor((pairWait * 1000) + (attempts * intervalSec * 1000) + 2000);

    const scriptPath = Quickshell.shellDir + "/Bin/bluetooth-connect.sh";
    btExec(["bash", scriptPath, String(addr), String(pairWait), String(attempts), String(intervalSec)]);
  }

  function connectDeviceWithTrust(device) {
    if (!device)
      return;
    device.trusted = true;
    device.connect();
  }

  function disconnectDevice(device) {
    if (!device)
      return;
    device.disconnect();
  }

  function forgetDevice(device) {
    if (!device)
      return;
    device.trusted = false;
    device.forget();
  }

  function btExec(args) {
    try {
      Quickshell.execDetached(args);
    } catch (_) {}
  }
}
