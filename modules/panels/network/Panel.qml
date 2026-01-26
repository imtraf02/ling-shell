pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.modules.panels
import qs.services
import qs.widgets

SmartPanel {
  id: root

  property string panelViewMode: "wifi"

  onPanelViewModeChanged: {
    if (Settings.network.networkPanelView !== panelViewMode)
      Settings.network.networkPanelView = panelViewMode;
  }

  onOpened: {
    NetworkService.scan();
    NetworkService.refreshActiveWifiDetails();
    NetworkService.refreshActiveEthernetDetails();

    if (Settings.network.networkPanelView) {
      const last = Settings.network.networkPanelView;
      if (last === "ethernet" && NetworkService.hasEthernet()) {
        panelViewMode = "ethernet";
      } else {
        panelViewMode = "wifi";
      }
    } else {
      if (!Settings.network.wifiEnabled && NetworkService.hasEthernet())
        panelViewMode = "ethernet";
      else
        panelViewMode = "wifi";
    }
  }

  panelContent: Item {
    property real contentPreferredWidth: Style.bar.networkWidth
    property real contentPreferredHeight: mainColumn.implicitHeight + Style.padding.small * 2

    anchors.fill: parent

    ColumnLayout {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: Style.padding.small
      spacing: Style.spacing.small

      // Header
      IBox {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + Style.padding.small * 2

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.padding.small
          spacing: Style.spacing.small

          IIcon {
            icon: root.panelViewMode === "wifi" ? (Settings.network.wifiEnabled ? "network_wifi" : "signal_wifi_off") : (NetworkService.hasEthernet() ? "lan" : "public_off")
            font.pointSize: Style.font.size.large
            color: root.panelViewMode === "wifi" ? (Settings.network.wifiEnabled ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurfaceVariant) : (NetworkService.ethernetConnected ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurfaceVariant)

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (root.panelViewMode === "wifi") {
                  if (NetworkService.hasEthernet())
                    root.panelViewMode = "ethernet";
                  else {}
                } else {
                  root.panelViewMode = "wifi";
                }
              }
            }
          }

          IText {
            text: root.panelViewMode === "wifi" ? "Wi-Fi" : "Ethernet"
            font.pointSize: Style.font.size.larger
            font.weight: Font.Medium
            Layout.fillWidth: true
          }

          ISwitch {
            visible: root.panelViewMode === "wifi"
            checked: Settings.network.wifiEnabled
            onToggled: {
              NetworkService.setWifiEnabled(checked);
            }
          }

          IIconButton {
            icon: "refresh"
            size: Style.widget.size * 0.8
            enabled: root.panelViewMode === "wifi" ? (Settings.network.wifiEnabled && !NetworkService.scanning) : true
            onClicked: {
              if (root.panelViewMode === "wifi")
                NetworkService.scan();
              else
                NetworkService.refreshEthernet();
            }
          }

          IIconButton {
            icon: "close"
            size: Style.widget.size * 0.8
            onClicked: root.close()
          }
        }
      }

      // Tab Switcher
      ITabBar {
        Layout.fillWidth: true
        ITabButton {
          text: "Wi-Fi"
          tabIndex: 0
          checked: root.panelViewMode === "wifi"
          onClicked: root.panelViewMode = "wifi"
        }
        ITabButton {
          text: "Ethernet"
          tabIndex: 1
          checked: root.panelViewMode === "ethernet"
          opacity: NetworkService.hasEthernet() ? 1.0 : 0.5
          onClicked: {
            if (NetworkService.hasEthernet())
              root.panelViewMode = "ethernet";
          }
        }
      }

      IDivider {
        Layout.fillWidth: true
      }

      // Error Message
      Rectangle {
        visible: root.panelViewMode === "wifi" && NetworkService.lastError.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: errorRow.implicitHeight + (Style.padding.small)
        color: Qt.alpha(ThemeService.palette.mError, 0.1)
        radius: Style.rounding.small
        border.width: 1
        border.color: ThemeService.palette.mError

        RowLayout {
          id: errorRow
          anchors.fill: parent
          anchors.margins: Style.padding.small
          spacing: Style.spacing.small

          IIcon {
            icon: "warning"
            font.pointSize: Style.font.size.large
            color: ThemeService.palette.mError
          }
          IText {
            text: NetworkService.lastError
            color: ThemeService.palette.mError
            font.pointSize: Style.font.size.small
            wrapMode: Text.Wrap
            Layout.fillWidth: true
          }
          IIconButton {
            icon: "close"
            size: Style.widget.size * 0.8
            onClicked: NetworkService.lastError = ""
          }
        }
      }

      // Content Area
      IFlickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(380, viewLoader.item ? viewLoader.item.implicitHeight : 0)
        contentHeight: viewLoader.item ? viewLoader.item.implicitHeight : 0
        clip: true

        Loader {
          id: viewLoader
          width: parent.width
          sourceComponent: root.panelViewMode === "wifi" ? wifiComp : ethernetComp

          Component {
            id: wifiComp
            WifiView {
              width: viewLoader.width
            }
          }

          Component {
            id: ethernetComp
            EthernetView {
              width: viewLoader.width
            }
          }
        }
      }
    }
  }
}
