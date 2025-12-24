pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.commons
import qs.widgets
import qs.services
import ".."

BarPanel {
  id: root

  onOpened: NetworkService.scan()

  contentComponent: Item {
    id: content

    property string passwordSsid: ""
    property string passwordInput: ""
    property string expandedSsid: ""

    implicitWidth: Config.bar.sizes.networkWidth
    implicitHeight: mainColumn.implicitHeight + (root.padding * 2)

    ColumnLayout {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: root.padding
      spacing: root.spacing

      IBox {
        id: headerBox
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + (root.padding * 2)

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: root.padding
          spacing: spacing

          IIcon {
            icon: Settings.network.wifiEnabled ? "wifi" : "wifi_off"
            pointSize: Config.appearance.font.size.large
            color: ThemeService.palette.mPrimary
          }

          IText {
            text: "Wi-Fi"
            pointSize: Config.appearance.font.size.larger
            color: ThemeService.palette.mOnSurface
            Layout.fillWidth: true
          }

          ISwitch {
            id: wifiSwitch
            checked: Settings.network.wifiEnabled
            onToggled: {
              NetworkService.setWifiEnabled(!Settings.network.wifiEnabled);
            }
          }

          IIconButton {
            icon: "refresh"
            size: Config.appearance.widget.size * 0.8
            enabled: Settings.network.wifiEnabled && !NetworkService.scanning
            onClicked: NetworkService.scan()
          }

          IIconButton {
            icon: "close"
            size: Config.appearance.widget.size * 0.8
            onClicked: root.close()
          }
        }
      }

      Rectangle {
        id: errorRect
        visible: NetworkService.lastError.length > 0
        Layout.fillWidth: true
        implicitHeight: visible ? errorRow.implicitHeight + root.padding * 2 : 0
        color: Qt.alpha(ThemeService.palette.mError, 0.1)
        radius: Settings.appearance.cornerRadius
        border.width: 2
        border.color: ThemeService.palette.mError

        RowLayout {
          id: errorRow
          anchors.fill: parent
          anchors.margins: root.padding
          spacing: spacing

          IIcon {
            icon: "warning"
            pointSize: Config.appearance.font.size.large
            color: ThemeService.palette.mError
          }

          IText {
            text: NetworkService.lastError
            color: ThemeService.palette.mError
            pointSize: Config.appearance.font.size.small
            wrapMode: Text.Wrap
            Layout.fillWidth: true
          }

          IIconButton {
            icon: "close"
            size: Config.appearance.widget.size * 0.6
            onClicked: NetworkService.lastError = ""
          }
        }
      }

      IBox {
        id: list
        Layout.fillWidth: true

        implicitHeight: {
          if (!Settings.network.wifiEnabled)
            return wifiDisabled.implicitHeight + (root.padding * 2);
          if (Settings.network.wifiEnabled && NetworkService.scanning && Object.keys(NetworkService.networks).length === 0)
            return wifiScanning.implicitHeight + (root.padding * 2);
          if (Settings.network.wifiEnabled && !NetworkService.scanning && Object.keys(NetworkService.networks).length === 0)
            return emptyState.implicitHeight + (root.padding * 2);

          return Math.min(networksFlickable.contentHeight + (root.padding * 2), 380);
        }

        ColumnLayout {
          id: wifiDisabled
          visible: !Settings.network.wifiEnabled
          anchors.fill: parent
          anchors.margins: root.padding

          Item {
            Layout.fillHeight: true
          }

          IIcon {
            icon: "wifi_off"
            pointSize: Config.appearance.widget.size
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          IText {
            text: "Wi-Fi is disabled"
            pointSize: Config.appearance.font.size.large
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          IText {
            text: "Enable Wi-Fi to connect to networks"
            pointSize: Config.appearance.font.size.small
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          Item {
            Layout.fillHeight: true
          }
        }

        ColumnLayout {
          id: wifiScanning
          visible: Settings.network.wifiEnabled && NetworkService.scanning && Object.keys(NetworkService.networks).length === 0
          anchors.fill: parent
          anchors.margins: root.padding
          spacing: spacing

          Item {
            Layout.fillHeight: true
          }

          IBusyIndicator {
            running: true
            color: ThemeService.palette.mPrimary
            size: Config.appearance.widget.size
            Layout.alignment: Qt.AlignHCenter
          }

          IText {
            text: "Searching for nearby networks..."
            pointSize: Config.appearance.font.size.small
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          Item {
            Layout.fillHeight: true
          }
        }

        IFlickable {
          id: networksFlickable
          visible: Settings.network.wifiEnabled && (!NetworkService.scanning || Object.keys(NetworkService.networks).length > 0)
          anchors.fill: parent
          anchors.margins: root.padding
          clip: true
          contentWidth: parent.width
          contentHeight: listContainer.implicitHeight
          boundsBehavior: Flickable.StopAtBounds

          ColumnLayout {
            id: listContainer
            width: networksFlickable.width
            spacing: root.padding

            Repeater {
              model: {
                if (!Settings.network.wifiEnabled)
                  return [];
                const nets = Object.values(NetworkService.networks);
                return nets.sort((a, b) => {
                  if (a.connected !== b.connected)
                    return b.connected - a.connected;
                  return b.signal - a.signal;
                });
              }

              Rectangle {
                id: wifiItem
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: netColumn.implicitHeight + (root.padding * 2)
                radius: Settings.appearance.cornerRadius
                opacity: (NetworkService.disconnectingFrom === modelData.ssid || NetworkService.forgettingNetwork === modelData.ssid) ? 0.6 : 1.0
                color: modelData.connected ? Qt.rgba(ThemeService.palette.mPrimary.r, ThemeService.palette.mPrimary.g, ThemeService.palette.mPrimary.b, 0.05) : ThemeService.palette.mSurface
                border.width: 2
                border.color: modelData.connected ? ThemeService.palette.mPrimary : Qt.alpha(ThemeService.palette.mOutline, 0.4)

                Behavior on opacity {
                  IAnim {}
                }

                ColumnLayout {
                  id: netColumn
                  width: parent.width - (root.padding * 2)
                  x: root.padding
                  y: root.padding
                  spacing: spacing

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: spacing

                    IIcon {
                      icon: NetworkService.signalIcon(wifiItem.modelData.signal, wifiItem.modelData.connected)
                      pointSize: Config.appearance.font.size.large
                      color: wifiItem.modelData.connected ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurface
                    }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 2

                      IText {
                        text: wifiItem.modelData.ssid
                        pointSize: Config.appearance.font.size.small
                        font.weight: wifiItem.modelData.connected ? Font.DemiBold : Font.Medium
                        color: ThemeService.palette.mOnSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                      }

                      RowLayout {
                        spacing: spacing

                        IText {
                          text: "Signal: " + wifiItem.modelData.signal + "%"
                          pointSize: Config.appearance.font.size.small
                          color: ThemeService.palette.mOnSurfaceVariant
                        }
                        IText {
                          text: "•"
                          pointSize: Config.appearance.font.size.small
                          color: ThemeService.palette.mOnSurfaceVariant
                        }
                        IText {
                          text: NetworkService.isSecured(wifiItem.modelData.security) ? wifiItem.modelData.security : "Open"
                          pointSize: Config.appearance.font.size.small
                          color: ThemeService.palette.mOnSurfaceVariant
                        }

                        Rectangle {
                          visible: wifiItem.modelData.connected && NetworkService.disconnectingFrom !== wifiItem.modelData.ssid
                          color: ThemeService.palette.mPrimary
                          radius: height * 0.5
                          Layout.preferredWidth: connectedText.implicitWidth + (root.spacing * 2)
                          Layout.preferredHeight: connectedText.implicitHeight + root.spacing

                          IText {
                            id: connectedText
                            anchors.centerIn: parent
                            text: "Connected"
                            pointSize: Config.appearance.font.size.small
                            color: ThemeService.palette.mOnPrimary
                          }
                        }

                        Rectangle {
                          visible: NetworkService.disconnectingFrom === wifiItem.modelData.ssid
                          color: ThemeService.palette.mError
                          radius: height * 0.5
                          Layout.preferredWidth: disconnectingText.implicitWidth + (root.spacing * 2)
                          Layout.preferredHeight: disconnectingText.implicitHeight + root.spacing

                          IText {
                            id: disconnectingText
                            anchors.centerIn: parent
                            text: "Disconnecting..."
                            pointSize: Config.appearance.font.size.small
                            color: ThemeService.palette.mOnPrimary
                          }
                        }

                        Rectangle {
                          visible: NetworkService.forgettingNetwork === wifiItem.modelData.ssid
                          color: ThemeService.palette.mError
                          radius: height * 0.5
                          Layout.preferredWidth: forgettingText.implicitWidth + (root.spacing * 2)
                          Layout.preferredHeight: forgettingText.implicitHeight + root.spacing

                          IText {
                            id: forgettingText
                            anchors.centerIn: parent
                            text: "Forgetting..."
                            pointSize: Config.appearance.font.size.small
                            color: ThemeService.palette.mOnPrimary
                          }
                        }

                        Rectangle {
                          visible: wifiItem.modelData.cached && !wifiItem.modelData.connected && NetworkService.forgettingNetwork !== wifiItem.modelData.ssid && NetworkService.disconnectingFrom !== wifiItem.modelData.ssid
                          color: "transparent"
                          border.color: Qt.alpha(ThemeService.palette.mOutline, 0.4)
                          border.width: 2
                          radius: height * 0.5
                          Layout.preferredWidth: savedText.implicitWidth + (root.spacing * 2)
                          Layout.preferredHeight: savedText.implicitHeight + root.spacing

                          IText {
                            id: savedText
                            anchors.centerIn: parent
                            text: "Saved"
                            pointSize: Config.appearance.font.size.small
                            color: ThemeService.palette.mOnSurfaceVariant
                          }
                        }
                      }
                    }

                    RowLayout {
                      spacing: root.spacing

                      IBusyIndicator {
                        visible: NetworkService.connectingTo === wifiItem.modelData.ssid || NetworkService.disconnectingFrom === wifiItem.modelData.ssid || NetworkService.forgettingNetwork === wifiItem.modelData.ssid
                        running: visible
                        size: Config.appearance.widget.size * 0.5
                        color: ThemeService.palette.mPrimary
                      }

                      IIconButton {
                        visible: (wifiItem.modelData.existing || wifiItem.modelData.cached) && !wifiItem.modelData.connected
                        icon: "delete"
                        size: Config.appearance.widget.size * 0.8
                        onClicked: content.expandedSsid = content.expandedSsid === wifiItem.modelData.ssid ? "" : wifiItem.modelData.ssid
                      }

                      IButton {
                        visible: !wifiItem.modelData.connected
                        text: "Connect"
                        outlined: true
                        fontSize: Config.appearance.font.size.small
                        enabled: !NetworkService.connecting
                        onClicked: {
                          if (wifiItem.modelData.existing || wifiItem.modelData.cached || !NetworkService.isSecured(wifiItem.modelData.security)) {
                            NetworkService.connect(wifiItem.modelData.ssid);
                          } else {
                            content.passwordSsid = wifiItem.modelData.ssid;
                            content.passwordInput = "";
                            content.expandedSsid = "";
                          }
                        }
                      }

                      IButton {
                        visible: wifiItem.modelData.connected
                        text: "Disconnect"
                        outlined: true
                        backgroundColor: ThemeService.palette.mError
                        hoverColor: ThemeService.palette.mError
                        fontSize: Config.appearance.font.size.small
                        onClicked: NetworkService.disconnect(wifiItem.modelData.ssid)
                      }
                    }
                  }

                  Rectangle {
                    visible: content.passwordSsid === wifiItem.modelData.ssid
                    Layout.fillWidth: true
                    Layout.preferredHeight: passwordRow.implicitHeight + (root.padding * 2)
                    color: ThemeService.palette.mSurfaceVariant
                    border.color: Qt.alpha(ThemeService.palette.mOutline, 0.4)
                    border.width: 2
                    radius: Settings.appearance.cornerRadius

                    RowLayout {
                      id: passwordRow
                      anchors.fill: parent
                      anchors.margins: root.padding
                      spacing: spacing

                      Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Settings.appearance.cornerRadius
                        color: ThemeService.palette.mSurface
                        border.color: pwdInput.activeFocus ? ThemeService.palette.mSecondary : ThemeService.palette.mOutline
                        border.width: 2

                        TextInput {
                          id: pwdInput
                          anchors.fill: parent
                          anchors.margins: root.spacing
                          text: content.passwordInput
                          font.pointSize: Config.appearance.font.size.small
                          color: ThemeService.palette.mOnSurface
                          echoMode: TextInput.Password
                          selectByMouse: true
                          focus: visible
                          passwordCharacter: "●"
                          onTextChanged: content.passwordInput = text
                          onVisibleChanged: if (visible)
                            forceActiveFocus()
                          onAccepted: {
                            if (text && !NetworkService.connecting) {
                              NetworkService.connect(content.passwordSsid, text);
                              content.passwordSsid = "";
                              content.passwordInput = "";
                            }
                          }

                          IText {
                            visible: parent.text.length === 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Enter password"
                            color: ThemeService.palette.mOnSurfaceVariant
                            pointSize: Config.appearance.font.size.small
                          }
                        }
                      }

                      IButton {
                        text: "Connect"
                        fontSize: Config.appearance.font.size.small
                        enabled: content.passwordInput.length > 0 && !NetworkService.connecting
                        outlined: true
                        onClicked: {
                          NetworkService.connect(content.passwordSsid, content.passwordInput);
                          content.passwordSsid = "";
                          content.passwordInput = "";
                        }
                      }

                      IIconButton {
                        icon: "close"
                        size: Config.appearance.widget.size * 0.8
                        onClicked: {
                          content.passwordSsid = "";
                          content.passwordInput = "";
                        }
                      }
                    }
                  }

                  Rectangle {
                    visible: content.expandedSsid === wifiItem.modelData.ssid
                    Layout.fillWidth: true
                    Layout.preferredHeight: forgetRow.implicitHeight + (root.padding * 2)
                    color: ThemeService.palette.mSurfaceVariant
                    radius: Settings.appearance.cornerRadius
                    border.width: 2
                    border.color: Qt.alpha(ThemeService.palette.mOutline, 0.4)

                    RowLayout {
                      id: forgetRow
                      anchors.fill: parent
                      anchors.margins: root.padding
                      spacing: spacing

                      RowLayout {
                        IIcon {
                          icon: "delete"
                          pointSize: Config.appearance.font.size.large
                          color: ThemeService.palette.mError
                        }

                        IText {
                          text: "Forget this network?"
                          pointSize: Config.appearance.font.size.small
                          color: ThemeService.palette.mError
                          Layout.fillWidth: true
                        }
                      }

                      IButton {
                        id: forgetButton
                        text: "Forget"
                        fontSize: Config.appearance.font.size.small
                        backgroundColor: ThemeService.palette.mError
                        outlined: forgetButton.hovered ? false : true
                        onClicked: {
                          NetworkService.forget(wifiItem.modelData.ssid);
                          content.expandedSsid = "";
                        }
                      }

                      IIconButton {
                        icon: "close"
                        size: Config.appearance.widget.size * 0.8
                        onClicked: content.expandedSsid = ""
                      }
                    }
                  }
                }
              }
            }
          }
        }

        ColumnLayout {
          id: emptyState
          visible: Settings.network.wifiEnabled && !NetworkService.scanning && Object.keys(NetworkService.networks).length === 0
          anchors.fill: parent
          anchors.margins: root.padding
          spacing: spacing

          Item {
            Layout.fillHeight: true
          }

          IIcon {
            icon: "search"
            pointSize: Config.appearance.widget.size
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          IText {
            text: "No networks found"
            pointSize: Config.appearance.font.size.large
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          IButton {
            text: "Scan again"
            icon: "refresh"
            Layout.alignment: Qt.AlignHCenter
            onClicked: NetworkService.scan()
          }

          Item {
            Layout.fillHeight: true
          }
        }
      }
    }
  }
}
