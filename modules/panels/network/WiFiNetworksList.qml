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

  property string label: ""
  property var model: []
  property var cachedModel: []
  readonly property var displayModel: (passwordSsid && passwordSsid.length > 0) ? cachedModel : model

  property string passwordSsid: ""
  property string expandedSsid: ""
  property string infoSsid: ""

  property bool detailsGrid: Settings.network.wifiDetailsViewMode === "grid"

  signal passwordRequested(string ssid)
  signal passwordSubmitted(string ssid, string password)
  signal passwordCancelled
  signal forgetRequested(string ssid)
  signal forgetConfirmed(string ssid)
  signal forgetCancelled

  onPasswordSsidChanged: {
    if (passwordSsid && passwordSsid.length > 0) {
      try {
        cachedModel = JSON.parse(JSON.stringify(model));
      } catch (e) {
        cachedModel = model;
      }
    } else {
      cachedModel = [];
    }
  }

  Layout.fillWidth: true
  spacing: Style.spacing.small
  visible: root.model.length > 0

  RowLayout {
    Layout.fillWidth: true
    visible: root.model.length > 0
    Layout.leftMargin: Style.padding.small
    spacing: Style.spacing.small

    IText {
      text: root.label
      font.pointSize: Style.font.size.small
      color: ThemeService.palette.mSecondary
      font.weight: Font.Medium
      Layout.fillWidth: true
    }
  }

  Repeater {
    model: root.displayModel

    IBox {
      id: networkItem
      required property var modelData

      Layout.fillWidth: true
      implicitHeight: netColumn.implicitHeight + (Style.padding.small * 2)

      opacity: (modelData && (NetworkService.disconnectingFrom === modelData.ssid || NetworkService.forgettingNetwork === modelData.ssid)) ? 0.6 : 1.0

      color: (modelData && modelData.connected) ? Qt.rgba(ThemeService.palette.mPrimary.r, ThemeService.palette.mPrimary.g, ThemeService.palette.mPrimary.b, 0.08) : ThemeService.palette.mSurface

      Behavior on opacity {
        IAnim {}
      }

      ColumnLayout {
        id: netColumn
        anchors.fill: parent
        anchors.margins: Style.padding.small
        spacing: Style.spacing.small

        // Main row
        RowLayout {
          Layout.fillWidth: true
          Layout.margins: Style.padding.small
          spacing: Style.spacing.small

          IIcon {
            icon: Icons.getNetworkIcon(networkItem.modelData ? networkItem.modelData.signal : 0, NetworkService.isSecured(networkItem.modelData.security))
            font.pointSize: Style.font.size.large
            color: (networkItem.modelData && networkItem.modelData.connected) ? (NetworkService.internetConnectivity ? ThemeService.palette.mPrimary : ThemeService.palette.mError) : ThemeService.palette.mOnSurface

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            IText {
              text: networkItem.modelData ? networkItem.modelData.ssid : ""
              font.pointSize: Style.font.size.small
              font.weight: Font.Medium
              color: ThemeService.palette.mOnSurface
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            RowLayout {
              spacing: Style.spacing.small

              IText {
                text: (networkItem.modelData && NetworkService.isSecured(networkItem.modelData.security)) ? networkItem.modelData.security : "Open"

                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurfaceVariant
              }

              IIcon {
                icon: "lock_open"
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurfaceVariant
                visible: networkItem.modelData && !NetworkService.isSecured(networkItem.modelData.security)
              }

              // Disconnecting Badge
              Rectangle {
                visible: networkItem.modelData && NetworkService.disconnectingFrom === networkItem.modelData.ssid
                color: ThemeService.palette.mError
                radius: height * 0.5
                Layout.preferredWidth: disconnectingText.contentWidth + (Style.spacing.small * 2)
                Layout.preferredHeight: disconnectingText.contentHeight

                IText {
                  id: disconnectingText
                  anchors.centerIn: parent
                  text: "Disconnecting..."
                  font.pointSize: 10
                  color: ThemeService.palette.mOnPrimary
                }
              }

              // Forgetting Badge
              Rectangle {
                visible: networkItem.modelData && NetworkService.forgettingNetwork === networkItem.modelData.ssid
                color: ThemeService.palette.mError
                radius: height * 0.5
                Layout.preferredWidth: forgettingText.contentWidth + (Style.spacing.small * 2)
                Layout.preferredHeight: forgettingText.contentHeight

                IText {
                  id: forgettingText
                  anchors.centerIn: parent
                  text: "Forgetting..."
                  font.pointSize: 10
                  color: ThemeService.palette.mOnPrimary
                }
              }

              // Connected Badge
              Rectangle {
                visible: (networkItem.modelData && networkItem.modelData.connected) && NetworkService.disconnectingFrom !== networkItem.modelData.ssid
                color: NetworkService.internetConnectivity ? ThemeService.palette.mPrimary : ThemeService.palette.mError
                radius: height * 0.5
                Layout.preferredWidth: connectedText.contentWidth + (Style.spacing.small * 2)
                Layout.preferredHeight: connectedText.contentHeight

                IText {
                  id: connectedText
                  anchors.centerIn: parent
                  text: {
                    if (NetworkService.networkConnectivity === "full")
                      return "Connected";
                    if (NetworkService.networkConnectivity === "limited")
                      return "Limited";
                    if (NetworkService.networkConnectivity === "portal")
                      return "Action Required";
                    return NetworkService.networkConnectivity;
                  }
                  font.pointSize: 10
                  color: ThemeService.palette.mOnPrimary
                }
              }

              // Saved Badge
              Rectangle {
                visible: (networkItem.modelData && networkItem.modelData.cached && !networkItem.modelData.connected) && NetworkService.forgettingNetwork !== networkItem.modelData.ssid && NetworkService.disconnectingFrom !== networkItem.modelData.ssid
                color: "transparent"
                border.color: ThemeService.palette.mOutline
                border.width: 1
                radius: height * 0.5
                Layout.preferredWidth: savedText.contentWidth + (Style.padding.small * 2)
                Layout.preferredHeight: savedText.contentHeight

                IText {
                  id: savedText
                  anchors.centerIn: parent
                  text: "Saved"
                  font.pointSize: 10
                  color: ThemeService.palette.mOnSurfaceVariant
                }
              }
            }
          }

          // Action area
          RowLayout {
            spacing: Style.spacing.small

            IBusyIndicator {
              visible: networkItem.modelData && (NetworkService.connectingTo === networkItem.modelData.ssid || NetworkService.disconnectingFrom === networkItem.modelData.ssid || NetworkService.forgettingNetwork === networkItem.modelData.ssid)
              running: visible
              color: ThemeService.palette.mPrimary
              size: Style.widget.size * 0.5
            }

            IIconButton {
              visible: (networkItem.modelData && networkItem.modelData.connected) && NetworkService.disconnectingFrom !== networkItem.modelData.ssid
              icon: "info"
              size: Style.widget.size * 0.8
              onClicked: {
                if (root.infoSsid === networkItem.modelData.ssid)
                  root.infoSsid = "";
                else {
                  root.infoSsid = networkItem.modelData.ssid;
                  NetworkService.refreshActiveWifiDetails();
                }
              }
            }

            IIconButton {
              visible: (networkItem.modelData && (networkItem.modelData.existing || networkItem.modelData.cached) && !networkItem.modelData.connected) && NetworkService.connectingTo !== networkItem.modelData.ssid && NetworkService.forgettingNetwork !== networkItem.modelData.ssid && NetworkService.disconnectingFrom !== networkItem.modelData.ssid
              icon: "delete"
              size: Style.widget.size * 0.8
              onClicked: root.forgetRequested(networkItem.modelData.ssid)
            }

            IButton {
              visible: !networkItem.modelData.connected && NetworkService.connectingTo !== networkItem.modelData.ssid && root.passwordSsid !== networkItem.modelData.ssid && NetworkService.forgettingNetwork !== networkItem.modelData.ssid && NetworkService.disconnectingFrom !== networkItem.modelData.ssid
              text: (networkItem.modelData.existing || networkItem.modelData.cached || !NetworkService.isSecured(networkItem.modelData.security)) ? "Connect" : "Password"
              outlined: !hovered
              fontSize: Style.font.size.small
              enabled: !NetworkService.connecting
              onClicked: {
                if (networkItem.modelData.existing || networkItem.modelData.cached || !NetworkService.isSecured(networkItem.modelData.security)) {
                  NetworkService.connect(networkItem.modelData.ssid);
                } else {
                  root.passwordRequested(networkItem.modelData.ssid);
                }
              }
            }

            IButton {
              visible: networkItem.modelData.connected && NetworkService.disconnectingFrom !== networkItem.modelData.ssid
              text: "Disconnect"
              outlined: !hovered
              fontSize: Style.font.size.small
              backgroundColor: ThemeService.palette.mError
              onClicked: NetworkService.disconnect(networkItem.modelData.ssid)
            }
          }
        }

        // Connection Info Details
        Rectangle {
          visible: root.infoSsid === networkItem.modelData.ssid && NetworkService.disconnectingFrom !== networkItem.modelData.ssid && NetworkService.forgettingNetwork !== networkItem.modelData.ssid
          Layout.fillWidth: true
          color: ThemeService.palette.mSurfaceVariant
          radius: Style.rounding.small
          border.width: 1
          border.color: Qt.alpha(ThemeService.palette.mOutline, 0.2)
          implicitHeight: infoGrid.implicitHeight + Style.padding.small * 2
          clip: true

          // Grid Toggle
          IIconButton {
            id: detailsToggle
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.padding.small
            icon: root.detailsGrid ? "view_list" : "grid_view"
            size: Style.widget.size * 0.8
            onClicked: {
              Settings.network.wifiDetailsViewMode = root.detailsGrid ? "list" : "grid";
            }
            z: 1
          }

          GridLayout {
            id: infoGrid
            anchors.fill: parent
            anchors.margins: Style.padding.small
            columns: root.detailsGrid ? 2 : 1
            columnSpacing: Style.spacing.small
            rowSpacing: Style.spacing.smaller

            // Rows...
            // Interface
            RowLayout {
              Layout.fillWidth: true
              spacing: Style.spacing.small
              IIcon {
                icon: "lan"
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurface
              }
              IText {
                text: NetworkService.activeWifiIf || "-"
                font.pointSize: Style.font.size.small
                Layout.fillWidth: true
                elide: Text.ElideRight
              }
            }
            // Band
            RowLayout {
              Layout.fillWidth: true
              spacing: Style.spacing.small
              IIcon {
                icon: "router"
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurface
              }
              IText {
                text: NetworkService.activeWifiDetails.band || "-"
                font.pointSize: Style.font.size.small
                Layout.fillWidth: true
              }
            }
            // Link Speed
            RowLayout {
              Layout.fillWidth: true
              spacing: Style.spacing.small
              IIcon {
                icon: "speed"
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurface
              }
              IText {
                text: NetworkService.activeWifiDetails.rateShort || NetworkService.activeWifiDetails.rate || "-"
                font.pointSize: Style.font.size.small
                Layout.fillWidth: true
              }
            }
            // IPv4
            RowLayout {
              Layout.fillWidth: true
              spacing: Style.spacing.small
              IIcon {
                icon: "dns"
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurface
              }
              IText {
                text: NetworkService.activeWifiDetails.ipv4 || "-"
                font.pointSize: Style.font.size.small
                Layout.fillWidth: true
              }
            }
            // Gateway
            RowLayout {
              Layout.fillWidth: true
              spacing: Style.spacing.small
              IIcon {
                icon: "router"
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurface
              }
              IText {
                text: NetworkService.activeWifiDetails.gateway4 || "-"
                font.pointSize: Style.font.size.small
                Layout.fillWidth: true
              }
            }
            // DNS
            RowLayout {
              Layout.fillWidth: true
              spacing: Style.spacing.small
              IIcon {
                icon: "public"
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurface
              }
              IText {
                text: NetworkService.activeWifiDetails.dns || "-"
                font.pointSize: Style.font.size.small
                Layout.fillWidth: true
              }
            }
          }
        }

        // Password Input
        Rectangle {
          visible: networkItem.modelData && root.passwordSsid === networkItem.modelData.ssid && NetworkService.disconnectingFrom !== networkItem.modelData.ssid && NetworkService.forgettingNetwork !== networkItem.modelData.ssid
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
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Style.padding.small
                font.family: Settings.appearance.font.mono
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurface
                echoMode: TextInput.Password
                selectByMouse: true
                focus: visible
                passwordCharacter: "●"
                onVisibleChanged: if (visible)
                  forceActiveFocus()
                onAccepted: {
                  if (text && !NetworkService.connecting) {
                    root.passwordSubmitted(networkItem.modelData.ssid, text);
                  }
                }

                IText {
                  visible: parent.text.length === 0
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
              enabled: pwdInput.text.length > 0 && !NetworkService.connecting
              outlined: true
              onClicked: root.passwordSubmitted(networkItem.modelData.ssid, pwdInput.text)
            }

            IIconButton {
              icon: "close"
              size: Style.widget.size * 0.8
              onClicked: root.passwordCancelled()
            }
          }
        }

        // Forget Network Confirmation
        Rectangle {
          visible: networkItem.modelData && root.expandedSsid === networkItem.modelData.ssid && NetworkService.disconnectingFrom !== networkItem.modelData.ssid && NetworkService.forgettingNetwork !== networkItem.modelData.ssid
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
              id: forgetButton
              text: "Forget"
              fontSize: Style.font.size.small
              backgroundColor: ThemeService.palette.mError
              outlined: !hovered
              onClicked: root.forgetConfirmed(networkItem.modelData.ssid)
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
