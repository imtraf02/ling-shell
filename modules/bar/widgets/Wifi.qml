import QtQuick
import Quickshell
import qs.services
import "../extras"

Item {
  id: root

  property ShellScreen screen

  implicitWidth: pill.width
  implicitHeight: pill.height

  BarPill {
    id: pill
    icon: {
      try {
        if (NetworkService.ethernetConnected) {
          return "lan";
        }
        let connected = false;
        let signalStrength = 0;
        for (const net in NetworkService.networks) {
          if (NetworkService.networks[net].connected) {
            connected = true;
            signalStrength = NetworkService.networks[net].signal;
            break;
          }
        }
        return connected ? NetworkService.signalIcon(signalStrength, true) : "wifi_off";
      } catch (error) {
        return "wifi_off";
      }
    }
    text: {
      try {
        if (NetworkService.ethernetConnected) {
          return "Ethernet";
        }
        for (const net in NetworkService.networks) {
          if (NetworkService.networks[net].connected) {
            return net;
          }
        }
        return "Not connected";
      } catch (error) {
        return "Error";
      }
    }
    onClicked: {
      VisibilityService.getPanel("wifi", root.screen)?.toggle(this);
    }
  }
}
