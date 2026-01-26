pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.services

Singleton {
  id: root
  property var networks: ({})
  property bool scanning: false
  property bool connecting: false
  property string connectingTo: ""
  property string lastError: ""
  property bool ethernetConnected: false

  property var ethernetInterfaces: ([])

  property var activeEthernetDetails: ({})
  property string activeEthernetIf: ""
  property bool ethernetDetailsLoading: false
  property double activeEthernetDetailsTimestamp: 0

  property int activeEthernetDetailsTtlMs: 5000
  property string disconnectingFrom: ""
  property string forgettingNetwork: ""
  property string networkConnectivity: "unknown"
  property bool internetConnectivity: true
  property bool ignoreScanResults: false
  property bool scanPending: false

  property var activeWifiDetails: ({})
  property string activeWifiIf: ""
  property bool detailsLoading: false
  property double activeWifiDetailsTimestamp: 0

  property int activeWifiDetailsTtlMs: 5000

  property string cacheFile: Directories.shellCacheNetworkPath
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
        if (!BluetoothService.airplaneModeToggled) {}

        delayedScanTimer.interval = 3000;
        delayedScanTimer.restart();
      } else {
        if (!BluetoothService.airplaneModeToggled) {}

        root.networks = ({});
      }
    }
  }
  Component.onCompleted: {
    if (ProgramCheckerService.nmcliAvailable) {
      syncWifiState();
      scan();

      refreshActiveWifiDetails();
      refreshActiveEthernetDetails();
    }
  }

  Connections {
    target: ProgramCheckerService
    function onNmcliAvailableChanged() {
      if (ProgramCheckerService.nmcliAvailable) {
        root.syncWifiState();
        root.scan();

        root.refreshActiveWifiDetails();
        root.refreshActiveEthernetDetails();
      }
    }
  }

  Timer {
    id: saveDebounce
    interval: 1000
    onTriggered: cacheFileView.writeAdapter()
  }

  function refreshActiveWifiDetails() {
    const now = Date.now();

    if (detailsLoading)
      return;

    if (activeWifiIf && activeWifiDetails && (now - activeWifiDetailsTimestamp) < activeWifiDetailsTtlMs)
      return;
    detailsLoading = true;
    deviceListProcess.running = true;
  }
  function saveCache() {
    saveDebounce.restart();
  }

  Timer {
    id: delayedScanTimer
    interval: 7000
    onTriggered: root.scan()
  }

  Timer {
    id: ethernetCheckTimer
    interval: 30000
    running: ProgramCheckerService.nmcliAvailable
    repeat: true
    onTriggered: deviceListProcess.running = true
  }

  function refreshActiveEthernetDetails() {
    const now = Date.now();
    if (ethernetDetailsLoading)
      return;
    if (!root.ethernetConnected) {
      root.activeEthernetDetails = ({});
      root.activeEthernetDetailsTimestamp = now;
      return;
    }

    if (activeEthernetIf && activeEthernetDetails && (now - activeEthernetDetailsTimestamp) < activeEthernetDetailsTtlMs)
      return;
    ethernetDetailsLoading = true;
    deviceListProcess.running = true;
  }

  Timer {
    id: connectivityCheckTimer
    interval: 15000
    running: ProgramCheckerService.nmcliAvailable
    repeat: true
    onTriggered: connectivityCheckProcess.running = true
  }

  function syncWifiState() {
    if (!ProgramCheckerService.nmcliAvailable)
      return;
    wifiStateProcess.running = true;
  }
  function setWifiEnabled(enabled) {
    if (!ProgramCheckerService.nmcliAvailable)
      return;
    Settings.network.wifiEnabled = enabled;
    wifiStateEnableProcess.running = true;
  }
  function scan() {
    if (!ProgramCheckerService.nmcliAvailable || !Settings.network.wifiEnabled)
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

  function hasEthernet() {
    return root.ethernetInterfaces && root.ethernetInterfaces.length > 0;
  }

  function refreshEthernet() {
    if (!ProgramCheckerService.nmcliAvailable)
      return;
    deviceListProcess.running = true;
    refreshActiveEthernetDetails();
  }
  function connect(ssid, password = "") {
    if (!ProgramCheckerService.nmcliAvailable || connecting)
      return;
    connecting = true;
    connectingTo = ssid;
    lastError = "";

    if ((networks[ssid] && networks[ssid].existing) || cachedNetworks[ssid]) {
      connectProcess.mode = "saved";
      connectProcess.ssid = ssid;
      connectProcess.password = "";
    } else {
      connectProcess.mode = "new";
      connectProcess.ssid = ssid;
      connectProcess.password = password;
    }
    connectProcess.running = true;
  }
  function disconnect(ssid) {
    if (!ProgramCheckerService.nmcliAvailable)
      return;
    disconnectingFrom = ssid;
    disconnectProcess.ssid = ssid;
    disconnectProcess.running = true;
  }
  function forget(ssid) {
    if (!ProgramCheckerService.nmcliAvailable)
      return;
    forgettingNetwork = ssid;

    let known = cacheAdapter.knownNetworks;
    delete known[ssid];
    cacheAdapter.knownNetworks = known;
    if (cacheAdapter.lastConnected === ssid) {
      cacheAdapter.lastConnected = "";
    }
    saveCache();

    forgetProcess.ssid = ssid;
    forgetProcess.running = true;
  }

  function updateNetworkStatus(ssid, connected) {
    let nets = networks;

    for (let key in nets) {
      if (nets[key].connected && key !== ssid) {
        nets[key].connected = false;
      }
    }

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

    // Emit change signal without resetting the object
    // This avoids destroying and recreating all Repeater delegates
    root.networksChanged();
  }

  function isSecured(security) {
    return security && security !== "--" && security.trim() !== "";
  }

  Process {
    id: deviceListProcess
    running: false
    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n");

        // Ethernet logic
        let ethConnected = false;
        let ethIf = "";
        const ethList = [];

        // Wifi logic
        let wifiIf = "";

        for (let i = 0; i < lines.length; i++) {
          const parts = lines[i].trim().split(":");
          if (parts.length >= 3) {
            const dev = parts[0];
            const type = parts[1];
            const state = parts[2];

            // Handle Ethernet
            if (type === "ethernet") {
              const isConn = state === "connected";
              ethList.push({
                ifname: dev,
                state: state,
                connected: isConn
              });

              if (isConn && !ethConnected) {
                ethConnected = true;
                ethIf = dev;
              }
            }

            // Handle Wifi
            if (type === "wifi" && state === "connected") {
              wifiIf = dev;
            }
          }
        }

        // Ethernet Update
        ethList.sort(function (a, b) {
          if (a.connected !== b.connected)
            return a.connected ? -1 : 1;
          return a.ifname.localeCompare(b.ifname);
        });
        root.ethernetInterfaces = ethList;
        if (root.ethernetConnected !== ethConnected) {
          root.ethernetConnected = ethConnected;
        }

        if (ethIf) {
          if (root.activeEthernetIf !== ethIf) {
            root.activeEthernetIf = ethIf;
            // Reset timestamp to force refresh if interface changed
            root.activeEthernetDetailsTimestamp = 0;
          }
          // Trigger details update for ethernet
          ethernetDeviceShowProcess.ifname = ethIf;
          ethernetDeviceShowProcess.running = true;
        } else {
          root.activeEthernetIf = "";
          root.activeEthernetDetails = ({});
          root.activeEthernetDetailsTimestamp = Date.now();
          root.ethernetDetailsLoading = false;
        }

        // Wifi Update
        root.activeWifiIf = wifiIf;
        if (wifiIf) {
          // Trigger details update for wifi
          wifiDeviceShowProcess.ifname = wifiIf;
          wifiDeviceShowProcess.running = true;
        } else {
          root.activeWifiDetailsTimestamp = Date.now();
          root.detailsLoading = false;
        }
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (!root.activeEthernetIf) {
          root.ethernetDetailsLoading = false;
        }
        if (!root.activeWifiIf) {
          root.detailsLoading = false;
        }
      }
    }
  }

  Process {
    id: wifiDeviceShowProcess
    property string ifname: ""
    running: false
    command: ["nmcli", "-t", "-f", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS", "device", "show", ifname]
    stdout: StdioCollector {
      onStreamFinished: {
        const details = root.activeWifiDetails || ({});
        let ipv4 = "";
        let gw4 = "";
        let dnsServers = [];
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i].trim();
          if (!line)
            continue;
          const idx = line.indexOf(":");
          if (idx === -1)
            continue;
          const key = line.substring(0, idx);
          const val = line.substring(idx + 1);
          if (key.indexOf("IP4.ADDRESS") === 0) {
            ipv4 = val.split("/")[0];
          } else if (key === "IP4.GATEWAY") {
            gw4 = val;
          } else if (key.indexOf("IP4.DNS") === 0) {
            if (val && dnsServers.indexOf(val) === -1) {
              dnsServers.push(val);
            }
          }
        }
        details.ipv4 = ipv4;
        details.gateway4 = gw4;
        details.dnsServers = dnsServers;
        details.dns = dnsServers.join(", ");
        root.activeWifiDetails = details;

        wifiIwLinkProcess.ifname = wifiDeviceShowProcess.ifname;
        wifiIwLinkProcess.running = true;
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text && text.trim()) {}

        root.activeWifiDetailsTimestamp = Date.now();
      }
    }
  }

  Process {
    id: wifiIwLinkProcess
    property string ifname: ""
    running: false
    command: ["sh", "-c", "iw dev '" + ifname + "' link 2>/dev/null || true"]
    stdout: StdioCollector {
      onStreamFinished: {
        const details = root.activeWifiDetails || ({});
        let rate = "";
        let freq = "";
        const lines = text.split("\n");
        for (let k = 0; k < lines.length; k++) {
          const line2 = lines[k].trim();
          const low = line2.toLowerCase();
          if (low.indexOf("tx bitrate:") === 0) {
            rate = line2.substring(11).trim();
          } else if (low.indexOf("freq:") === 0) {
            freq = line2.substring(5).trim();
          }
        }
        let band = "";
        if (freq) {
          const f = +freq;
          if (f) {
            switch (true) {
            case (f >= 5925 && f < 7125):
              band = "6 GHz";
              break;
            case (f >= 5150 && f < 5925):
              band = "5 GHz";
              break;
            case (f >= 2400 && f < 2500):
              band = "2.4 GHz";
              break;
            default:
              band = `${f} MHz`;
            }
          }
        }
        let rateShort = "";
        if (rate) {
          const parts = rate.trim().split(" ");
          const compact = [];
          for (let i = 0; i < parts.length; i++) {
            const p = parts[i];
            if (p && p.length > 0)
              compact.push(p);
          }
          let unitIdx = -1;
          for (let j = 0; j < compact.length; j++) {
            const token = compact[j].toLowerCase();
            if (token === "mbit/s" || token === "mb/s" || token === "mbits/s") {
              unitIdx = j;
              break;
            }
          }
          if (unitIdx > 0) {
            const num = compact[unitIdx - 1];
            const parsed = parseFloat(num);
            if (!isNaN(parsed)) {
              rateShort = parsed + " Mbit/s";
            }
          }
          if (!rateShort) {
            rateShort = compact.slice(0, 2).join(" ");
          }
        }
        details.rate = rate;
        details.rateShort = rateShort;
        details.band = band;
        root.activeWifiDetails = details;
        root.activeWifiDetailsTimestamp = Date.now();
        root.detailsLoading = false;
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text && text.trim()) {}
        root.activeWifiDetailsTimestamp = Date.now();
        root.detailsLoading = false;
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
        if (Settings.network.wifiEnabled !== enabled) {
          Settings.network.wifiEnabled = enabled;
        }
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text && text.trim()) {}
      }
    }
  }

  Process {
    id: wifiStateEnableProcess
    running: false
    command: ["nmcli", "radio", "wifi", Settings.network.wifiEnabled ? "on" : "off"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.syncWifiState();
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {}
      }
    }
  }

  Process {
    id: connectivityCheckProcess
    running: false
    command: ["nmcli", "networking", "connectivity", "check"]
    property int failedChecks: 0
    stdout: StdioCollector {
      onStreamFinished: {
        const result = text.trim();
        if (!result) {
          return;
        }
        if (result === "none" && root.networkConnectivity !== result) {
          root.networkConnectivity = result;
          connectivityCheckProcess.failedChecks = 0;
          root.scan();
        }
        if (result === "full" && root.networkConnectivity !== result) {
          root.networkConnectivity = result;
          root.internetConnectivity = true;
          connectivityCheckProcess.failedChecks = 0;
          root.scan();
        }
        if ((result === "limited" || result === "portal") && root.networkConnectivity !== result) {
          connectivityCheckProcess.failedChecks++;
          if (connectivityCheckProcess.failedChecks === 3) {
            root.networkConnectivity = result;
            pingCheckProcess.running = true;
          }
        }
        if (result === "unknown" && root.networkConnectivity !== result) {
          root.networkConnectivity = result;
          connectivityCheckProcess.failedChecks = 0;
        }
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {}
      }
    }
  }
  Process {
    id: pingCheckProcess
    command: ["sh", "-c", "ping -c1 -W2 ping.archlinux.org >/dev/null 2>&1 || " + "ping -c1 -W2 1.1.1.1 >/dev/null 2>&1 || " + "curl -fsI --max-time 5 https://cloudflare.com/cdn-cgi/trace >/dev/null 2>&1"]
    onExited: function (exitCode, exitStatus) {
      if (exitCode === 0) {
        connectivityCheckProcess.failedChecks = 0;
      } else {
        root.internetConnectivity = false;
        connectivityCheckProcess.failedChecks = 0;
      }
      root.scan();
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
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
          const l = lines[i];
          if (l && l.trim()) {
            profiles[l.trim()] = true;
          }
        }
        scanProcess.existingProfiles = profiles;
        scanProcess.running = true;
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text && text.trim()) {
          if (root.scanning) {
            root.scanning = false;
            delayedScanTimer.interval = 5000;
            delayedScanTimer.restart();
          }
        }
      }
    }
  }
  Process {
    id: scanProcess
    running: false
    command: ["nmcli", "-t", "-f", "SSID,SECURITY,SIGNAL,IN-USE", "device", "wifi", "list", "--rescan", "yes"]
    property var existingProfiles: ({})
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
        for (let i = 0; i < lines.length; ++i) {
          const line = lines[i].trim();
          if (!line)
            continue;
          const lastColonIdx = line.lastIndexOf(":");
          if (lastColonIdx === -1) {
            continue;
          }
          const inUse = line.substring(lastColonIdx + 1);
          const remainingLine = line.substring(0, lastColonIdx);
          const secondLastColonIdx = remainingLine.lastIndexOf(":");
          if (secondLastColonIdx === -1) {
            continue;
          }
          const signal = remainingLine.substring(secondLastColonIdx + 1);
          const remainingLine2 = remainingLine.substring(0, secondLastColonIdx);
          const thirdLastColonIdx = remainingLine2.lastIndexOf(":");
          if (thirdLastColonIdx === -1) {
            continue;
          }
          const security = remainingLine2.substring(thirdLastColonIdx + 1);
          const ssid = remainingLine2.substring(0, thirdLastColonIdx);
          if (ssid) {
            const signalInt = parseInt(signal) || 0;
            const connected = inUse === "*";
            if (connected && cacheAdapter.lastConnected !== ssid) {
              cacheAdapter.lastConnected = ssid;
              root.saveCache();
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
              if (connected) {
                existingNet.connected = true;
              }
              if (signalInt > existingNet.signal) {
                existingNet.signal = signalInt;
                existingNet.security = security || "--";
              }
            }
          }
        }

        root.networks = networksMap;
        root.scanning = false;
        let hasConnected = false;
        for (const ssid in networksMap) {
          if (networksMap.hasOwnProperty(ssid)) {
            const net = networksMap[ssid];
            if (net && net.connected) {
              hasConnected = true;
              break;
            }
          }
        }
        if (hasConnected) {
          root.refreshActiveWifiDetails();
        }
        if (root.scanPending) {
          root.scanPending = false;
          delayedScanTimer.interval = 100;
          delayedScanTimer.restart();
        }
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        root.scanning = false;
        if (text.trim()) {
          delayedScanTimer.interval = 5000;
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
    environment: ({
        "LC_ALL": "C"
      })
    command: {
      if (mode === "saved") {
        return ["nmcli", "connection", "up", "id", ssid];
      } else {
        let cmd = ["nmcli", "device", "wifi", "connect", ssid];
        if (password) {
          cmd.push("password", password);
        }
        return cmd;
      }
    }
    stdout: StdioCollector {
      onStreamFinished: {
        const output = text.trim();
        if (!output || (output.indexOf("successfully activated") === -1 && output.indexOf("Connection successfully") === -1)) {
          return;
        }

        let known = cacheAdapter.knownNetworks;
        known[connectProcess.ssid] = {
          "profileName": connectProcess.ssid,
          "lastConnected": Date.now()
        };
        cacheAdapter.knownNetworks = known;
        cacheAdapter.lastConnected = connectProcess.ssid;
        root.saveCache();

        root.updateNetworkStatus(connectProcess.ssid, true);

        root.refreshActiveWifiDetails();
        root.connecting = false;
        root.connectingTo = "";

        delayedScanTimer.interval = 5000;
        delayedScanTimer.restart();
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        root.connecting = false;
        root.connectingTo = "";
        if (text.trim()) {
          if (text.indexOf("Secrets were required") !== -1 || text.indexOf("no secrets provided") !== -1) {
            root.lastError = "Incorrect password";
            root.forget(connectProcess.ssid);
          } else if (text.indexOf("No network with SSID") !== -1) {
            root.lastError = "Network not found";
          } else if (text.indexOf("Timeout") !== -1) {
            root.lastError = "Connection timeout";
          } else {
            root.lastError = "Connection failed";
          }
        }
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

    command: {
      let script = "";
      script += "ssid=\"$1\"\n";
      script += "deleted=false\n\n";
      script += "if nmcli connection delete id \"$ssid\" 2>/dev/null; then\n";
      script += "  echo \"Deleted profile: $ssid\"\n";
      script += "  deleted=true\n";
      script += "fi\n\n";
      script += "if nmcli connection delete id \"Auto $ssid\" 2>/dev/null; then\n";
      script += "  echo \"Deleted profile: Auto $ssid\"\n";
      script += "  deleted=true\n";
      script += "fi\n\n";
      script += "for i in 1 2 3; do\n";
      script += "  if nmcli connection delete id \"$ssid $i\" 2>/dev/null; then\n";
      script += "    echo \"Deleted profile: $ssid $i\"\n";
      script += "    deleted=true\n";
      script += "  fi\n";
      script += "done\n\n";
      script += "if [ \"$deleted\" = \"false\" ]; then\n";
      script += "  echo \"No profiles found for SSID: $ssid\"\n";
      script += "fi\n";
      return ["sh", "-c", script, "--", ssid];
    }
    stdout: StdioCollector {
      onStreamFinished: {
        let nets = root.networks;
        if (nets[forgetProcess.ssid]) {
          nets[forgetProcess.ssid].cached = false;
          nets[forgetProcess.ssid].existing = false;

          // Emit change signal without resetting the object
          root.networksChanged();
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
