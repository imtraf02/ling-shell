import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.utils
import qs.widgets

GridLayout {
  id: root

  required property var panel

  columns: 2
  rowSpacing: Style.spacing.small
  columnSpacing: Style.spacing.small

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
          ssid = "";
          signal = 0;
          security = "";
          return;
        }

        isEthernet = false;
        connected = false;

        const networks = NetworkService.networks;
        for (const net in networks) {
          const n = networks[net];
          if (n.connected) {
            connected = true;
            signal = n.signal || 0;
            ssid = net;
            security = NetworkService.isSecured(n.security) ? n.security : "Open";
            return;
          }
        }

        ssid = "";
        signal = 0;
        security = "";
      } catch (e) {
        console.error("Network state update error:", e);
        connected = false;
        isEthernet = false;
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

  QuickToggleTile {
    icon: {
      if (!netState.connected)
        return "signal_wifi_off";

      return netState.isEthernet ? "lan" : Icons.getNetworkIcon(netState.signal, NetworkService.isSecured(netState.security));
    }

    title: {
      if (!netState.connected)
        return "No network";

      return netState.isEthernet ? "Ethernet" : netState.ssid;
    }

    showDetails: true
    active: Settings.network.wifiEnabled
    onClicked: NetworkService.setWifiEnabled(!Settings.network.wifiEnabled)
    onDetailsClicked: PanelService.getPanel("panel:network", root.panel.screen).toggle(root.panel.buttonItem)
  }

  QuickToggleTile {
    id: btPill

    readonly property var connectedDevices: BluetoothService.connectedDevices || []
    readonly property int deviceCount: connectedDevices.length
    readonly property var primaryDevice: deviceCount > 0 ? connectedDevices[0] : null

    icon: BluetoothService.enabled ? Icons.getBluetoothDeviceIcon(primaryDevice) : "bluetooth_disabled"

    title: {
      if (!BluetoothService.enabled)
        return "Bluetooth off";

      if (deviceCount === 0)
        return "Bluetooth";

      if (deviceCount === 1)
        return primaryDevice.name || primaryDevice.deviceName || "Connected device";

      return `${deviceCount} devices`;
    }

    active: BluetoothService.enabled
    showDetails: true
    onClicked: BluetoothService.setBluetoothEnabled(!BluetoothService.enabled)
    onDetailsClicked: PanelService.getPanel("panel:bluetooth", root.panel.screen).toggle(root.panel.buttonItem)
  }

  QuickToggleTile {
    id: outputPill

    readonly property var sink: AudioService.sink
    readonly property bool muted: AudioService.muted
    readonly property bool hasDevice: sink !== null && sink !== undefined

    icon: AudioService.getOutputIcon()

    title: {
      if (!hasDevice)
        return "No output device";

      return sink.description || sink.name || "Audio output";
    }

    active: !muted && hasDevice
    showDetails: true
    interactive: hasDevice

    onClicked: {
      if (sink?.audio)
        sink.audio.muted = !muted;
    }

    onDetailsClicked: PanelService.getPanel("panel:audio", root.panel.screen).toggle(root.panel.buttonItem)
  }

  QuickToggleTile {
    id: inputPill

    readonly property var source: AudioService.source
    readonly property bool muted: AudioService.inputMuted
    readonly property bool hasDevice: source !== null && source !== undefined

    icon: AudioService.getInputIcon()

    title: {
      if (!hasDevice)
        return "No input device";

      return source.description || source.name || "Audio input";
    }

    active: !muted && hasDevice
    showDetails: true
    interactive: hasDevice

    onClicked: {
      if (source?.audio)
        source.audio.muted = !muted;
    }

    onDetailsClicked: PanelService.getPanel("panel:audio", root.panel.screen).toggle(root.panel.buttonItem)
  }

  QuickToggleTile {
    id: themePill

    readonly property bool isDark: Settings.appearance.theme.mode === "dark"

    icon: isDark ? "dark_mode" : "light_mode"
    title: isDark ? "Dark mode" : "Light mode"
    interactive: !ThemeService.loading

    onClicked: {
      Settings.appearance.theme.mode = isDark ? "light" : "dark";
    }
  }

  component QuickToggleTile: ColumnLayout {
    id: tile

    property string icon: "skull"
    property string title: "Title"
    property bool active: false
    property bool interactive: true
    property bool showDetails: false
    signal clicked
    signal detailsClicked

    spacing: Style.padding.small

    RowLayout {
      id: content
      Layout.fillWidth: true
      Layout.preferredHeight: 48
      spacing: 0

      Rectangle {
        id: iconSection
        Layout.fillWidth: !tile.showDetails
        Layout.preferredWidth: tile.showDetails ? parent.width / 2 : parent.width
        Layout.fillHeight: true

        topLeftRadius: Settings.appearance.cornerRadius
        bottomLeftRadius: Settings.appearance.cornerRadius
        topRightRadius: tile.showDetails ? 0 : Settings.appearance.cornerRadius
        bottomRightRadius: tile.showDetails ? 0 : Settings.appearance.cornerRadius

        color: iconMouseArea.containsMouse && tile.interactive ? (tile.active ? ThemeService.palette.mPrimaryContainer : ThemeService.palette.mSurfaceContainerHigh) : (tile.active ? ThemeService.palette.mPrimary : ThemeService.palette.mSurfaceContainer)

        border.color: Qt.alpha(ThemeService.palette.mPrimary, 0.4)
        border.width: 1

        Behavior on color {
          ICAnim {}
        }

        IIcon {
          anchors.centerIn: parent
          icon: tile.icon

          color: iconMouseArea.containsMouse && tile.interactive ? (tile.active ? ThemeService.palette.mOnPrimaryContainer : ThemeService.palette.mOnSurface) : (tile.active ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface)

          Behavior on color {
            ICAnim {}
          }
        }

        MouseArea {
          id: iconMouseArea
          anchors.fill: parent
          enabled: tile.interactive
          cursorShape: tile.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
          hoverEnabled: true
          onClicked: tile.clicked()
          onPressed: iconSection.scale = 0.95
          onReleased: iconSection.scale = 1.0
        }

        Behavior on scale {
          IAnim {}
        }
      }

      Rectangle {
        id: chevronSection
        visible: tile.showDetails
        Layout.fillWidth: true
        Layout.preferredWidth: tile.showDetails ? parent.width / 2 : 0
        Layout.fillHeight: true

        topRightRadius: Settings.appearance.cornerRadius
        bottomRightRadius: Settings.appearance.cornerRadius
        topLeftRadius: 0
        bottomLeftRadius: 0

        color: chevronMouseArea.containsMouse && tile.interactive ? (tile.active ? ThemeService.palette.mPrimaryContainer : ThemeService.palette.mSurfaceContainerHigh) : (tile.active ? ThemeService.palette.mPrimary : ThemeService.palette.mSurfaceContainer)

        border.color: Qt.alpha(ThemeService.palette.mPrimary, 0.4)
        border.width: 1

        Behavior on color {
          ICAnim {}
        }

        IIcon {
          anchors.centerIn: parent
          icon: "chevron_right"

          color: chevronMouseArea.containsMouse && tile.interactive ? (tile.active ? ThemeService.palette.mOnPrimaryContainer : ThemeService.palette.mOnSurface) : (tile.active ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface)

          Behavior on color {
            ICAnim {}
          }
        }

        MouseArea {
          id: chevronMouseArea
          anchors.fill: parent
          enabled: tile.interactive
          cursorShape: tile.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
          hoverEnabled: true
          onClicked: tile.detailsClicked()
          onPressed: chevronSection.scale = 0.95
          onReleased: chevronSection.scale = 1.0
        }

        Behavior on scale {
          IAnim {}
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: titleText.implicitHeight

      IText {
        id: titleText
        text: tile.title
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        maximumLineCount: 1
        elide: Text.ElideRight
        font.pointSize: Style.font.size.small
      }
    }
  }
}
