import QtQuick
import Quickshell
import qs.services
import qs.utils
import qs.modules.bar.extras

Item {
  id: root

  property ShellScreen screen

  implicitWidth: pill.width
  implicitHeight: pill.height

  QtObject {
    id: netState

    property bool isEthernet: false
    property bool hasWifiConnection: false
    property int wifiSignal: 0
    property string connectedSsid: ""

    function update() {
      try {
        const networks = NetworkService.networks;

        isEthernet = NetworkService.ethernetConnected;

        if (isEthernet) {
          hasWifiConnection = false;
          wifiSignal = 0;
          connectedSsid = "";
          return;
        }

        hasWifiConnection = false;
        for (const ssid in networks) {
          const network = networks[ssid];
          if (network.connected) {
            hasWifiConnection = true;
            wifiSignal = network.signal || 0;
            connectedSsid = ssid;
            return;
          }
        }

        wifiSignal = 0;
        connectedSsid = "";
      } catch (e) {
        console.error("Network state error:", e);
        isEthernet = false;
        hasWifiConnection = false;
        wifiSignal = 0;
        connectedSsid = "";
      }
    }
  }

  Connections {
    target: NetworkService
    function onNetworksChanged() {
      netState.update();
    }
    function onEthernetConnectedChanged() {
      netState.update();
    }
  }

  Component.onCompleted: {
    ProgramCheckerService.ensure("nmcliAvailable");
    netState.update();
  }

  BarPill {
    id: pill

    icon: {
      if (netState.isEthernet)
        return "lan";

      if (netState.hasWifiConnection)
        return Icons.getNetworkIcon(netState.wifiSignal);

      return "signal_wifi_off";
    }

    text: {
      try {
        if (NetworkService.connecting && NetworkService.connectingTo)
          return `Connecting to ${NetworkService.connectingTo}...`;

        if (NetworkService.disconnectingFrom)
          return `Disconnecting...`;

        if (netState.isEthernet) {
          const iface = NetworkService.activeEthernetIf;
          return iface ? `Ethernet (${iface})` : "Ethernet";
        }

        if (netState.hasWifiConnection)
          return netState.connectedSsid;

        if (!NetworkService.internetConnectivity)
          return "No Internet";

        return "Disconnected";
      } catch (e) {
        console.error("Network text error:", e);
        return NetworkService.lastError || "Network Error";
      }
    }

    onClicked: {
      PanelService.getPanel("panel:network", root.screen).toggle(pill);
    }
  }
}
