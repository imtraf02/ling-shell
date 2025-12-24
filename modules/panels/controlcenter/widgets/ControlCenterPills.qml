import QtQuick
import QtQuick.Layouts
import qs.config
import qs.commons
import qs.services

ColumnLayout {
  id: root

  required property var panel

  readonly property int padding: Config.appearance.padding.normal
  readonly property int spacing: Config.appearance.spacing.small

  QtObject {
    id: netState
    property bool connected: false
    property int signal: 0
    property string ssid: ""
    property string security: ""
    property bool isEthernet: false

    function update() {
      try {
        if (NetworkService.ethernetConnected) {
          isEthernet = true;
          connected = true;
          return;
        }
        isEthernet = false;
        connected = false;

        // Loop 1 lần duy nhất
        for (const net in NetworkService.networks) {
          let n = NetworkService.networks[net];
          if (n.connected) {
            connected = true;
            signal = n.signal;
            ssid = net;
            security = NetworkService.isSecured(n.security) ? n.security : "Open";
            return;
          }
        }
      } catch (e) {
        connected = false;
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
  Component.onCompleted: netState.update()

  GridLayout {
    Layout.fillWidth: true
    columns: 2
    rowSpacing: root.spacing
    columnSpacing: root.spacing

    CompoundPill {
      Layout.fillWidth: true

      icon: {
        if (!netState.connected)
          return "wifi_off";
        return netState.isEthernet ? "lan" : NetworkService.signalIcon(netState.signal, true);
      }
      title: {
        if (!netState.connected)
          return "Not connected";
        return netState.isEthernet ? "Ethernet" : netState.ssid;
      }
      description: {
        if (!netState.connected)
          return "Select network";
        if (netState.isEthernet)
          return "Connected";
        return `${netState.signal}% • ${netState.security}`;
      }

      isActive: Settings.network.wifiEnabled
      onToggled: NetworkService.setWifiEnabled(!Settings.network.wifiEnabled)
      onClicked: VisibilityService.getPanel("wifi", root.panel.screen).toggle(root.panel.buttonItem)
    }

    CompoundPill {
      Layout.fillWidth: true

      readonly property var connected: BluetoothService.connectedDevices || []
      readonly property int connectedCount: connected.length
      readonly property var primaryDevice: connectedCount > 0 ? connected[0] : null

      icon: BluetoothService.enabled ? BluetoothService.getDeviceIcon(primaryDevice) : "bluetooth_disabled"
      title: {
        if (!BluetoothService.enabled)
          return "Bluetooth off";

        if (connectedCount === 1)
          return primaryDevice.name || primaryDevice.deviceName || "Connected device";

        if (connectedCount > 1)
          return `${connectedCount} devices`;

        return "Bluetooth";
      }
      description: {
        if (!BluetoothService.enabled)
          return "Turn on Bluetooth";

        if (primaryDevice) {
          let parts = [];

          let status = BluetoothService.getStatusString(primaryDevice);
          if (status.length > 0)
            parts.push(status);
          else
            parts.push("Connected");

          if (primaryDevice.batteryAvailable)
            parts.push(`${Math.round(primaryDevice.battery * 100)}%`);

          return parts.join(" • ");
        }

        if (BluetoothService.discovering)
          return "Scanning for devices…";

        return "No devices connected";
      }

      isActive: BluetoothService.enabled
      onToggled: BluetoothService.setBluetoothEnabled(!BluetoothService.enabled)
      onClicked: VisibilityService.getPanel("bluetooth", root.panel.screen).toggle(root.panel.buttonItem)
    }

    CompoundPill {
      Layout.fillWidth: true

      readonly property var sink: AudioService.sink
      readonly property real vol: AudioService.volume
      readonly property bool muted: AudioService.muted

      icon: AudioService.getOutputIcon()
      title: {
        if (!sink)
          return "Audio output";

        return sink.description || sink.name || "Audio output";
      }
      description: {
        if (!sink)
          return "No output device";

        if (muted)
          return "Muted";

        let percent = Math.round(vol * 100);
        let parts = [`${percent}%`];

        if (vol > 1.0)
          parts.push("Boost");

        return parts.join(" • ");
      }
      isActive: !muted
      onToggled: {
        if (sink?.audio)
          sink.audio.muted = !muted;
      }
      onClicked: VisibilityService.getPanel("audio", root.panel.screen).toggle(root.panel.buttonItem)
    }

    CompoundPill {
      Layout.fillWidth: true

      readonly property var source: AudioService.source
      readonly property real vol: AudioService.inputVolume
      readonly property bool muted: AudioService.inputMuted

      icon: AudioService.getInputIcon()
      title: {
        if (!source)
          return "Audio input";

        return source.description || source.name || "Audio input";
      }
      description: {
        if (!source)
          return "No input device";

        if (muted)
          return "Muted";

        return `${Math.round(vol * 100)}%`;
      }
      isActive: !muted
      onToggled: {
        if (source?.audio)
          source.audio.muted = !muted;
      }
      onClicked: VisibilityService.getPanel("audio", root.panel.screen).toggle(root.panel.buttonItem)
    }

    CompoundPill {
      Layout.fillWidth: true

      readonly property bool isDark: Settings.appearance.theme.mode === "dark"

      icon: isDark ? "dark_mode" : "light_mode"
      title: isDark ? "Dark mode" : "Light mode"
      description: isDark ? "Switch to light mode" : "Switch to dark mode"
      isActive: isDark
      onToggled: Settings.appearance.theme.mode = isDark ? "light" : "dark"
      onClicked: Settings.appearance.theme.mode = isDark ? "light" : "dark"
      enabled: !ThemeService.loading
    }
  }
}
