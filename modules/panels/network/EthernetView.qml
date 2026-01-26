pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

ColumnLayout {
  id: root

  property bool ethernetInfoExpanded: false
  property bool ethernetDetailsGrid: Settings.network.wifiDetailsViewMode === "grid"

  Component.onCompleted: {
    if (NetworkService.ethernetConnected) {
      NetworkService.refreshActiveEthernetDetails();
    } else {
      NetworkService.refreshEthernet();
    }
  }

  anchors.margins: Style.padding.small
  spacing: Style.spacing.small

  IText {
    text: "Available Interfaces"
    font.pointSize: Style.font.size.normal
    color: ThemeService.palette.mOnSurface
  }

  // Empty Eth
  IBox {
    visible: !(NetworkService.ethernetInterfaces && NetworkService.ethernetInterfaces.length > 0)
    Layout.fillWidth: true
    implicitHeight: 100
    ColumnLayout {
      anchors.centerIn: parent
      IIcon {
        icon: "public_off"
        font.pointSize: 40
        color: ThemeService.palette.mOnSurfaceVariant
        Layout.alignment: Qt.AlignHCenter
      }
      IText {
        text: "No Ethernet devices found"
        font.pointSize: Style.font.size.small
        color: ThemeService.palette.mOnSurfaceVariant
      }
    }
  }

  // Eth Interfaces List
  ColumnLayout {
    visible: NetworkService.ethernetInterfaces && NetworkService.ethernetInterfaces.length > 0
    Layout.fillWidth: true
    spacing: Style.spacing.small

    Repeater {
      model: NetworkService.ethernetInterfaces || []
      delegate: IBox {
        id: ethernetItem
        required property var modelData

        Layout.fillWidth: true
        implicitHeight: ethCol.implicitHeight + Style.padding.small * 2
        color: modelData.connected ? Qt.rgba(ThemeService.palette.mPrimary.r, ThemeService.palette.mPrimary.g, ThemeService.palette.mPrimary.b, 0.05) : ThemeService.palette.mSurface

        ColumnLayout {
          id: ethCol
          anchors.fill: parent
          anchors.margins: Style.padding.small
          spacing: Style.spacing.small

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.spacing.small

            IIcon {
              icon: "lan"
              font.pointSize: Style.font.size.extraLarge
              color: ethernetItem.modelData.connected ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurface
            }

            ColumnLayout {
              Layout.fillWidth: true
              IText {
                text: ethernetItem.modelData.ifname
                font.pointSize: Style.font.size.normal
                font.weight: Font.Medium
                Layout.fillWidth: true
              }
              RowLayout {
                // Connected Badge
                Rectangle {
                  visible: ethernetItem.modelData.connected
                  color: ThemeService.palette.mPrimary
                  radius: height * 0.5
                  Layout.preferredWidth: ethConnText.implicitWidth + 10
                  Layout.preferredHeight: ethConnText.implicitHeight + 4
                  IText {
                    id: ethConnText
                    text: "Connected"
                    color: ThemeService.palette.mOnPrimary
                    font.pointSize: Style.font.size.small
                    anchors.centerIn: parent
                  }
                }
              }
            }

            IIconButton {
              icon: "info"
              size: Style.widget.size * 0.8
              onClicked: {
                if (NetworkService.activeEthernetIf === ethernetItem.modelData.ifname && root.ethernetInfoExpanded) {
                  root.ethernetInfoExpanded = false;
                  return;
                }
                if (NetworkService.activeEthernetIf !== ethernetItem.modelData.ifname) {
                  NetworkService.activeEthernetIf = ethernetItem.modelData.ifname;
                  NetworkService.activeEthernetDetailsTimestamp = 0;
                }
                root.ethernetInfoExpanded = true;
                NetworkService.refreshActiveEthernetDetails();
              }
            }
          }

          // Details
          Rectangle {
            visible: root.ethernetInfoExpanded && NetworkService.activeEthernetIf === ethernetItem.modelData.ifname
            Layout.fillWidth: true
            color: ThemeService.palette.mSurfaceVariant
            radius: Style.rounding.small
            border.width: 1
            border.color: ThemeService.palette.mOutline
            implicitHeight: ethInfoGrid.implicitHeight + Style.padding.small * 2
            clip: true

            IIconButton {
              anchors.top: parent.top
              anchors.right: parent.right
              anchors.margins: Style.padding.small
              icon: root.ethernetDetailsGrid ? "view_list" : "grid_view"
              size: Style.widget.size * 0.8
              onClicked: root.ethernetDetailsGrid = !root.ethernetDetailsGrid
              z: 1
            }

            GridLayout {
              id: ethInfoGrid
              anchors.fill: parent
              anchors.margins: Style.padding.small
              columns: root.ethernetDetailsGrid ? 2 : 1
              columnSpacing: Style.spacing.small
              rowSpacing: Style.spacing.smaller

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.spacing.small
                IIcon {
                  icon: "lan"
                  font.pointSize: Style.font.size.small
                  color: ThemeService.palette.mOnSurface
                }
                IText {
                  text: (NetworkService.activeEthernetDetails.ifname || NetworkService.activeEthernetIf || "-")
                  font.pointSize: Style.font.size.small
                  Layout.fillWidth: true
                }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: Style.spacing.small
                IIcon {
                  icon: ethernetItem.modelData.connected ? (NetworkService.internetConnectivity ? "public" : "public_off") : "public_off"
                  font.pointSize: Style.font.size.small
                  color: ethernetItem.modelData.connected ? (NetworkService.internetConnectivity ? ThemeService.palette.mOnSurface : ThemeService.palette.mError) : ThemeService.palette.mError
                }
                IText {
                  text: ethernetItem.modelData.connected ? (NetworkService.internetConnectivity ? "Internet Connected" : "Limited") : "Disconnected"
                  font.pointSize: Style.font.size.small
                  color: ethernetItem.modelData.connected ? (NetworkService.internetConnectivity ? ThemeService.palette.mOnSurface : ThemeService.palette.mError) : ThemeService.palette.mError
                  Layout.fillWidth: true
                }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: Style.spacing.small
                IIcon {
                  icon: "speed"
                  font.pointSize: Style.font.size.small
                  color: ThemeService.palette.mOnSurface
                }
                IText {
                  text: NetworkService.activeEthernetDetails.speed || "-"
                  font.pointSize: Style.font.size.small
                  Layout.fillWidth: true
                }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: Style.spacing.small
                IIcon {
                  icon: "dns"
                  font.pointSize: Style.font.size.small
                  color: ThemeService.palette.mOnSurface
                }
                IText {
                  text: NetworkService.activeEthernetDetails.ipv4 || "-"
                  font.pointSize: Style.font.size.small
                  Layout.fillWidth: true
                }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: Style.spacing.small
                IIcon {
                  icon: "router"
                  font.pointSize: Style.font.size.small
                  color: ThemeService.palette.mOnSurface
                }
                IText {
                  text: NetworkService.activeEthernetDetails.gateway4 || "-"
                  font.pointSize: Style.font.size.small
                  Layout.fillWidth: true
                }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: Style.spacing.small
                IIcon {
                  icon: "public"
                  font.pointSize: Style.font.size.small
                  color: ThemeService.palette.mOnSurface
                }
                IText {
                  text: NetworkService.activeEthernetDetails.dns || "-"
                  font.pointSize: Style.font.size.small
                  Layout.fillWidth: true
                }
              }
            }
          }
        }
      }
    }
  }
}
