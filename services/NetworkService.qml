pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons

Singleton {
  id: root

  property var networks: ({})
  property bool scanning: false
  property bool connecting: false
  property string connectingTo: ""
  property string lastError: ""
  property bool ethernetConnected: false
  property string disconnectingFrom: ""
  property string forgettingNetwork: ""
  property string internetConnectivity: "unknown"

  property bool ignoreScanResults: false
  property bool scanPending: false

  property string cacheFile: Directories.shellStateNetworkPath
  readonly property string cachedLastConnected: cacheAdapter.lastConnected
  readonly property var cachedNetworks: cacheAdapter.knownNetworks

  FileView {
    id: cacheFileView
    path: root.cacheFile
    printErrors: false

    JsonAdapter {
      id: cacheAdapter
      property var knownNetworks: ({})
      property string lastConnected: ""
    }

    onLoadFailed: {
      cacheAdapter.knownNetworks = ({});
      cacheAdapter.lastConnected = "";
    }
  }

  Connections {
    target: Settings.network

    function onWifiEnabledChanged() {
      if (Settings.network.wifiEnabled) {
        if (!BluetoothService.airplaneModeToggled)
          ToastService.showNotice("Wi-Fi", "Enabled", "wifi");

        delayedScanTimer.interval = 3000;
        delayedScanTimer.restart();
      } else {
        if (!BluetoothService.airplaneModeToggled)
          ToastService.showNotice("Wi-Fi", "Disabled", "wifi_off");

        root.networks = ({});
      }
    }
  }

  Component.onCompleted: {
    syncWifiState();
    scan();
  }

  Timer {
    id: saveDebounce
    interval: 1000
    onTriggered: cacheFileView.writeAdapter()
  }

  Timer {
    id: delayedScanTimer
    interval: 7000
    onTriggered: scan()
  }

  Timer {
    id: ethernetCheckTimer
    interval: 30000
    running: true
    repeat: true
    onTriggered: ethernetStateProcess.running = true
  }

  Timer {
    id: connectivityCheckTimer
    interval: 10000
    running: true
    repeat: true
    onTriggered: connectivityCheckProcess.running = true
  }

  function saveCache() {
    saveDebounce.restart();
  }
  function syncWifiState() {
    wifiStateProcess.running = true;
  }
  function setWifiEnabled(enabled) {
    Settings.network.wifiEnabled = enabled;
    wifiStateEnableProcess.running = true;
  }

  function scan() {
    if (!Settings.network.wifiEnabled)
      return;
    if (scanning) {
      ignoreScanResults = true;
      scanPending = true;
      return;
    }

    scanning = true;
    lastError = "";
    ignoreScanResults = false;
    profileCheckProcess.running = true;
  }

  function connect(ssid, password = "") {
    if (connecting)
      return;
    connecting = true;
    connectingTo = ssid;
    lastError = "";

    if (networks[ssid]?.existing || cachedNetworks[ssid]) {
      connectProcess.mode = "saved";
      connectProcess.password = "";
    } else {
      connectProcess.mode = "new";
      connectProcess.password = password;
    }

    connectProcess.ssid = ssid;
    connectProcess.running = true;
  }

  function disconnect(ssid) {
    disconnectingFrom = ssid;
    disconnectProcess.ssid = ssid;
    disconnectProcess.running = true;
  }

  function forget(ssid) {
    forgettingNetwork = ssid;

    let known = cacheAdapter.knownNetworks;
    delete known[ssid];
    cacheAdapter.knownNetworks = known;

    if (cacheAdapter.lastConnected === ssid)
      cacheAdapter.lastConnected = "";

    saveCache();

    forgetProcess.ssid = ssid;
    forgetProcess.running = true;
  }

  function updateNetworkStatus(ssid, connected) {
    let nets = networks;

    for (let key in nets)
      if (nets[key].connected && key !== ssid)
        nets[key].connected = false;

    if (nets[ssid]) {
      nets[ssid].connected = connected;
      nets[ssid].existing = true;
      nets[ssid].cached = true;
    } else if (connected) {
      nets[ssid] = {
        "ssid": ssid,
        "security": "--",
        "signal": 100,
        "connected": true,
        "existing": true,
        "cached": true
      };
    }

    networks = ({});
    networks = nets;
  }

  function signalIcon(signal, isConnected = false) {
    if (isConnected && (internetConnectivity === "limited" || internetConnectivity === "portal"))
      return "wifi_off";
    if (signal >= 80)
      return "wifi";
    if (signal >= 50)
      return "wifi_2_bar";
    if (signal >= 20)
      return "wifi_1_bar";
    return "wifi_1_bar";
  }

  function isSecured(security) {
    return security && security !== "--" && security.trim() !== "";
  }

  Process {
    id: ethernetStateProcess
    running: true
    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device"]

    stdout: StdioCollector {
      onStreamFinished: {
        const connected = text.split("\n").some(line => {
          const parts = line.split(":");
          return parts[1] === "ethernet" && parts[2] === "connected";
        });
        if (root.ethernetConnected !== connected)
          root.ethernetConnected = connected;
      }
    }
  }

  Process {
    id: wifiStateProcess
    running: false
    command: ["nmcli", "radio", "wifi"]

    stdout: StdioCollector {
      onStreamFinished: {
        const enabled = text.trim() === "enabled";
        if (Settings.network.wifiEnabled !== enabled)
          Settings.network.wifiEnabled = enabled;
      }
    }
  }

  Process {
    id: wifiStateEnableProcess
    running: false
    command: ["nmcli", "radio", "wifi", Settings.network.wifiEnabled ? "on" : "off"]

    stdout: StdioCollector {
      onStreamFinished: syncWifiState()
    }
  }

  Process {
    id: connectivityCheckProcess
    running: false
    command: ["nmcli", "networking", "connectivity"]

    stdout: StdioCollector {
      onStreamFinished: {
        const result = text.trim();
        if (result && result !== root.internetConnectivity) {
          root.internetConnectivity = result;

          if (result === "limited" || result === "portal")
            ToastService.showWarning(cachedLastConnected, "toast.internet.limited");
          else
            scan();
        }
      }
    }
  }

  Process {
    id: profileCheckProcess
    running: false
    command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]

    stdout: StdioCollector {
      onStreamFinished: {
        if (root.ignoreScanResults) {
          root.scanning = false;
          if (root.scanPending) {
            root.scanPending = false;
            delayedScanTimer.interval = 100;
            delayedScanTimer.restart();
          }
          return;
        }

        const profiles = {};
        const lines = text.split("\n").filter(l => l.trim());
        for (const line of lines)
          profiles[line.trim()] = true;

        scanProcess.existingProfiles = profiles;
        scanProcess.running = true;
      }
    }
  }

  Process {
    id: scanProcess
    running: false
    property var existingProfiles: ({})
    command: ["nmcli", "-t", "-f", "SSID,SECURITY,SIGNAL,IN-USE", "device", "wifi", "list", "--rescan", "yes"]

    stdout: StdioCollector {
      onStreamFinished: {
        if (root.ignoreScanResults) {
          root.scanning = false;
          if (root.scanPending) {
            root.scanPending = false;
            delayedScanTimer.interval = 100;
            delayedScanTimer.restart();
          }
          return;
        }

        const lines = text.split("\n");
        const networksMap = {};

        for (let line of lines) {
          line = line.trim();
          if (!line)
            continue;
          const parts = line.split(":");
          if (parts.length < 4)
            continue;
          const inUse = parts.pop();
          const signal = parts.pop();
          const security = parts.pop();
          const ssid = parts.join(":");

          if (ssid) {
            const signalInt = parseInt(signal) || 0;
            const connected = inUse === "*";

            if (connected && cacheAdapter.lastConnected !== ssid) {
              cacheAdapter.lastConnected = ssid;
              saveCache();
            }

            if (!networksMap[ssid]) {
              networksMap[ssid] = {
                "ssid": ssid,
                "security": security || "--",
                "signal": signalInt,
                "connected": connected,
                "existing": ssid in scanProcess.existingProfiles,
                "cached": ssid in cacheAdapter.knownNetworks
              };
            } else {
              const existingNet = networksMap[ssid];
              if (connected)
                existingNet.connected = true;
              if (signalInt > existingNet.signal) {
                existingNet.signal = signalInt;
                existingNet.security = security || "--";
              }
            }
          }
        }

        root.networks = networksMap;
        root.scanning = false;

        if (root.scanPending) {
          root.scanPending = false;
          delayedScanTimer.interval = 100;
          delayedScanTimer.restart();
        }
      }
    }
  }

  Process {
    id: connectProcess
    property string mode: "new"
    property string ssid: ""
    property string password: ""
    running: false

    command: {
      if (mode === "saved")
        return ["nmcli", "connection", "up", "id", ssid];
      const cmd = ["nmcli", "device", "wifi", "connect", ssid];
      if (password)
        cmd.push("password", password);
      return cmd;
    }

    environment: {
      "LC_ALL": "C"
    }

    stdout: StdioCollector {
      onStreamFinished: {
        const output = text.trim();
        if (!output.includes("successfully activated") && !output.includes("Connection successfully"))
          return;
        let known = cacheAdapter.knownNetworks;

        known[connectProcess.ssid] = {
          "profileName": connectProcess.ssid,
          "lastConnected": Date.now()
        };
        cacheAdapter.knownNetworks = known;
        cacheAdapter.lastConnected = connectProcess.ssid;
        saveCache();

        root.updateNetworkStatus(connectProcess.ssid, true);
        root.connecting = false;
        root.connectingTo = "";

        ToastService.showNotice("Wi-fi", "Connected: " + connectProcess.ssid, "wifi");

        delayedScanTimer.interval = 5000;
        delayedScanTimer.restart();
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        root.connecting = false;
        root.connectingTo = "";
        if (!text.trim())
          return;
        if (text.includes("Secrets were required") || text.includes("no secrets provided"))
          root.lastError = "Incorrect password", forget(connectProcess.ssid);
        else if (text.includes("No network with SSID"))
          root.lastError = "Network not found";
        else if (text.includes("Timeout"))
          root.lastError = "Connection timeout";
        else
          root.lastError = text.split("\n")[0].trim();
      }
    }
  }

  Process {
    id: disconnectProcess
    property string ssid: ""
    running: false
    command: ["nmcli", "connection", "down", "id", ssid]

    stdout: StdioCollector {
      onStreamFinished: {
        ToastService.showNotice("Wi-fi", "Disconnected: " + disconnectProcess.ssid, "wifi_off");
        root.updateNetworkStatus(disconnectProcess.ssid, false);
        root.disconnectingFrom = "";
        delayedScanTimer.interval = 1000;
        delayedScanTimer.restart();
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        root.disconnectingFrom = "";
        delayedScanTimer.interval = 5000;
        delayedScanTimer.restart();
      }
    }
  }

  Process {
    id: forgetProcess
    property string ssid: ""
    running: false
    command: ["sh", "-c", `
            ssid="$1"; deleted=false
            if nmcli connection delete id "$ssid" 2>/dev/null; then deleted=true; fi
            if nmcli connection delete id "Auto $ssid" 2>/dev/null; then deleted=true; fi
            for i in 1 2 3; do
              if nmcli connection delete id "$ssid $i" 2>/dev/null; then deleted=true; fi
            done
            [ "$deleted" = false ] && echo "No profiles found for SSID: $ssid"
        `, "--", ssid]

    stdout: StdioCollector {
      onStreamFinished: {
        let nets = root.networks;
        if (nets[forgetProcess.ssid]) {
          nets[forgetProcess.ssid].cached = false;
          nets[forgetProcess.ssid].existing = false;
          root.networks = ({});
          root.networks = nets;
        }

        root.forgettingNetwork = "";
        delayedScanTimer.interval = 5000;
        delayedScanTimer.restart();
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        root.forgettingNetwork = "";
        delayedScanTimer.interval = 5000;
        delayedScanTimer.restart();
      }
    }
  }
}
