pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets
import qs.utils

ColumnLayout {
  id: root

  property var model: []
  property var cachedModel: []
  readonly property var displayModel: passwordSsid ? cachedModel : model

  property string passwordSsid: ""
  property string expandedSsid: ""
  property string selectedSsid: ""
  property string infoSsid: ""

  property bool detailsGrid: Settings.network.wifiDetailsViewMode === "grid"

  signal passwordRequested(string ssid)
  signal passwordSubmitted(string ssid, string password)
  signal passwordCancelled
  signal selectedRequested(string ssid)
  signal forgetRequested(string ssid)
  signal forgetConfirmed(string ssid)
  signal forgetCancelled

  Layout.fillWidth: true
  spacing: Style.spacing.small
  visible: model.length > 0

  onPasswordSsidChanged: {
    cachedModel = passwordSsid ? JSON.parse(JSON.stringify(model)) : [];
  }

  Repeater {
    model: root.displayModel

    IBox {
      id: networkItem
      required property var modelData

      Layout.fillWidth: true
      implicitHeight: netColumn.implicitHeight + Style.padding.small * 2

      readonly property bool isConnected: modelData?.connected ?? false
      readonly property bool isDisconnecting: modelData && NetworkService.disconnectingFrom === modelData.ssid
      readonly property bool isForgetting: modelData && NetworkService.forgettingNetwork === modelData.ssid
      readonly property bool isProcessing: isDisconnecting || isForgetting
      readonly property bool isHovered: itemMouseArea.containsMouse

      opacity: isProcessing ? 0.6 : 1.0

      color: isHovered || root.selectedSsid === modelData?.ssid ? ThemeService.palette.mSurfaceVariant : ThemeService.palette.mSurface

      Behavior on opacity {
        IAnim {}
      }
      Behavior on color {
        ICAnim {}
      }

      MouseArea {
        id: itemMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.selectedRequested(networkItem.modelData.ssid)
      }

      ColumnLayout {
        id: netColumn
        anchors.fill: parent
        anchors.margins: Style.padding.small
        spacing: Style.spacing.small

        // Main Network Info Row
        RowLayout {
          Layout.fillWidth: true
          Layout.margins: Style.padding.small
          spacing: Style.spacing.small

          IIcon {
            Layout.alignment: Qt.AlignTop
            icon: Icons.getNetworkIcon(modelData?.signal ?? 0, NetworkService.isSecured(modelData?.security))
            font.pointSize: Style.font.size.large
            color: {
              if (!isConnected)
                return ThemeService.palette.mOnSurface;
              return NetworkService.internetConnectivity ? ThemeService.palette.mPrimary : ThemeService.palette.mError;
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            IText {
              text: modelData?.ssid ?? ""
              font.pointSize: Style.font.size.small
              font.weight: Font.Medium
              color: ThemeService.palette.mOnSurface
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            RowLayout {
              spacing: Style.spacing.small

              IText {
                text: NetworkService.isSecured(modelData?.security) ? modelData.security : "Open"
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurfaceVariant
              }

              IIcon {
                visible: modelData && !NetworkService.isSecured(modelData.security)
                icon: "lock_open"
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurfaceVariant
              }

              // Disconnecting Badge
              Rectangle {
                visible: isDisconnecting
                color: ThemeService.palette.mError
                radius: height * 0.5
                Layout.preferredWidth: disconnectingText.contentWidth + Style.spacing.small * 2
                Layout.preferredHeight: disconnectingText.contentHeight

                IText {
                  id: disconnectingText
                  anchors.centerIn: parent
                  text: "Disconnecting..."
                  font.pointSize: Style.font.size.small
                  color: ThemeService.palette.mOnPrimary
                }
              }

              // Forgetting Badge
              Rectangle {
                visible: isForgetting
                color: ThemeService.palette.mError
                radius: height * 0.5
                Layout.preferredWidth: forgettingText.contentWidth + Style.spacing.small * 2
                Layout.preferredHeight: forgettingText.contentHeight

                IText {
                  id: forgettingText
                  anchors.centerIn: parent
                  text: "Forgetting..."
                  font.pointSize: Style.font.size.small
                  color: ThemeService.palette.mOnPrimary
                }
              }

              // Connected Badge
              Rectangle {
                visible: isConnected && !isDisconnecting
                color: NetworkService.internetConnectivity ? ThemeService.palette.mPrimary : ThemeService.palette.mError
                radius: height * 0.5
                Layout.preferredWidth: connectedText.contentWidth + Style.spacing.small * 2
                Layout.preferredHeight: connectedText.contentHeight

                IText {
                  id: connectedText
                  anchors.centerIn: parent
                  text: {
                    const conn = NetworkService.networkConnectivity;
                    if (conn === "full")
                      return "Connected";
                    if (conn === "limited")
                      return "Limited";
                    if (conn === "portal")
                      return "Action Required";
                    return conn;
                  }
                  font.pointSize: Style.font.size.small
                  color: ThemeService.palette.mOnPrimary
                }
              }

              Rectangle {
                visible: modelData?.cached && !isConnected && !isForgetting && !isDisconnecting
                color: "transparent"
                border.color: ThemeService.palette.mOutline
                border.width: 1
                radius: height * 0.5
                Layout.preferredWidth: savedText.contentWidth + Style.padding.small * 2
                Layout.preferredHeight: savedText.contentHeight

                IText {
                  id: savedText
                  anchors.centerIn: parent
                  text: "Saved"
                  font.pointSize: Style.font.size.small
                  color: ThemeService.palette.mOnSurfaceVariant
                }
              }
            }
          }

          // Action Icons
          RowLayout {
            visible: root.selectedSsid === modelData?.ssid
            spacing: Style.spacing.small

            IBusyIndicator {
              visible: modelData && (NetworkService.connectingTo === modelData.ssid || isDisconnecting || isForgetting)
              running: visible
              color: ThemeService.palette.mPrimary
              size: Style.widget.size * 0.5
            }

            IIconButton {
              visible: isConnected && !isDisconnecting
              Layout.alignment: Qt.AlignTop
              icon: "info"
              size: Style.widget.size * 0.8
              onClicked: {
                root.infoSsid = root.infoSsid === modelData.ssid ? "" : modelData.ssid;
                if (root.infoSsid)
                  NetworkService.refreshActiveWifiDetails();
              }
            }

            IIconButton {
              visible: (modelData?.existing || modelData?.cached) && !isConnected && !NetworkService.connectingTo === modelData.ssid && !isForgetting && !isDisconnecting
              Layout.alignment: Qt.AlignTop
              icon: "delete"
              size: Style.widget.size * 0.8
              onClicked: root.forgetRequested(modelData.ssid)
            }
          }
        }

        // Connect/Disconnect Buttons
        RowLayout {
          visible: root.selectedSsid === modelData?.ssid
          Layout.fillWidth: true
          Layout.margins: Style.padding.small
          Layout.alignment: Qt.AlignRight
          spacing: Style.spacing.small

          IButton {
            visible: !isConnected && NetworkService.connectingTo !== modelData.ssid && root.passwordSsid !== modelData.ssid && !isForgetting && !isDisconnecting
            text: "Connect"
            outlined: !hovered
            fontSize: Style.font.size.small
            enabled: !NetworkService.connecting
            onClicked: {
              if (modelData.existing || modelData.cached || !NetworkService.isSecured(modelData.security)) {
                NetworkService.connect(modelData.ssid);
              } else {
                root.passwordRequested(modelData.ssid);
              }
            }
          }

          IButton {
            visible: isConnected && !isDisconnecting
            text: "Disconnect"
            outlined: !hovered
            fontSize: Style.font.size.small
            backgroundColor: ThemeService.palette.mError
            onClicked: NetworkService.disconnect(modelData.ssid)
          }
        }

        // Connection Info Details
        Rectangle {
          visible: root.infoSsid === modelData?.ssid && !isDisconnecting && !isForgetting
          Layout.fillWidth: true
          color: ThemeService.palette.mSurfaceContainer
          radius: Style.rounding.small
          implicitHeight: infoGrid.implicitHeight + Style.padding.small * 2
          clip: true

          IIconButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.padding.small
            icon: root.detailsGrid ? "view_list" : "grid_view"
            size: Style.widget.size * 0.8
            onClicked: Settings.network.wifiDetailsViewMode = root.detailsGrid ? "list" : "grid"
            z: 1
          }

          GridLayout {
            id: infoGrid
            anchors.fill: parent
            anchors.margins: Style.padding.small
            columns: root.detailsGrid ? 2 : 1
            columnSpacing: Style.spacing.small
            rowSpacing: Style.spacing.smaller

            Repeater {
              model: [
                {
                  icon: "lan",
                  text: NetworkService.activeWifiIf || "-"
                },
                {
                  icon: "router",
                  text: NetworkService.activeWifiDetails.band || "-"
                },
                {
                  icon: "speed",
                  text: NetworkService.activeWifiDetails.rateShort || NetworkService.activeWifiDetails.rate || "-"
                },
                {
                  icon: "dns",
                  text: NetworkService.activeWifiDetails.ipv4 || "-"
                },
                {
                  icon: "router",
                  text: NetworkService.activeWifiDetails.gateway4 || "-"
                },
                {
                  icon: "public",
                  text: NetworkService.activeWifiDetails.dns || "-"
                }
              ]

              RowLayout {
                required property var modelData

                Layout.fillWidth: true
                spacing: Style.spacing.small

                IIcon {
                  icon: parent.modelData.icon
                  font.pointSize: Style.font.size.small
                  color: ThemeService.palette.mOnSurface
                }

                IText {
                  text: parent.modelData.text
                  font.pointSize: Style.font.size.small
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }
            }
          }
        }

        // Password Input
        Rectangle {
          visible: root.passwordSsid === modelData?.ssid && !isDisconnecting && !isForgetting
          Layout.fillWidth: true
          Layout.preferredHeight: passwordRow.implicitHeight + Style.padding.small * 2
          color: ThemeService.palette.mSurfaceVariant
          border.color: ThemeService.palette.mOutline
          border.width: 1
          radius: Style.rounding.small

          RowLayout {
            id: passwordRow
            anchors.fill: parent
            anchors.margins: Style.padding.small
            spacing: Style.spacing.small

            Rectangle {
              Layout.fillWidth: true
              Layout.fillHeight: true
              radius: Style.rounding.small
              color: ThemeService.palette.mSurface
              border.color: pwdInput.activeFocus ? ThemeService.palette.mSecondary : ThemeService.palette.mOutline
              border.width: 1

              TextInput {
                id: pwdInput
                anchors.fill: parent
                anchors.margins: Style.padding.small
                font.family: Settings.appearance.font.mono
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurface
                echoMode: TextInput.Password
                selectByMouse: true
                passwordCharacter: "●"
                verticalAlignment: TextInput.AlignVCenter

                onVisibleChanged: if (visible)
                  forceActiveFocus()
                onAccepted: {
                  if (text && !NetworkService.connecting)
                    root.passwordSubmitted(modelData.ssid, text);
                }

                IText {
                  visible: !parent.text
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Enter Password"
                  color: ThemeService.palette.mOnSurfaceVariant
                  font.pointSize: Style.font.size.small
                }
              }
            }

            IButton {
              text: "Connect"
              fontSize: Style.font.size.small
              enabled: pwdInput.text && !NetworkService.connecting
              outlined: true
              onClicked: root.passwordSubmitted(modelData.ssid, pwdInput.text)
            }

            IIconButton {
              icon: "close"
              size: Style.widget.size * 0.8
              onClicked: root.passwordCancelled()
            }
          }
        }

        // Forget Confirmation
        Rectangle {
          visible: root.expandedSsid === modelData?.ssid && !isDisconnecting && !isForgetting
          Layout.fillWidth: true
          Layout.preferredHeight: forgetRow.implicitHeight + Style.padding.small * 2
          color: ThemeService.palette.mSurfaceVariant
          radius: Style.rounding.small
          border.width: 1
          border.color: ThemeService.palette.mOutline

          RowLayout {
            id: forgetRow
            anchors.fill: parent
            anchors.margins: Style.padding.small
            spacing: Style.spacing.small

            RowLayout {
              IIcon {
                icon: "delete"
                font.pointSize: Style.font.size.normal
                color: ThemeService.palette.mError
              }

              IText {
                text: "Forget this network?"
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mError
                Layout.fillWidth: true
              }
            }

            IButton {
              text: "Forget"
              fontSize: Style.font.size.small
              backgroundColor: ThemeService.palette.mError
              outlined: !hovered
              onClicked: root.forgetConfirmed(modelData.ssid)
            }

            IIconButton {
              icon: "close"
              size: Style.widget.size * 0.8
              onClicked: root.forgetCancelled()
            }
          }
        }
      }
    }
  }
}
