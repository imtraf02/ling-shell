pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.widgets
import qs.services
import qs.commons
import Quickshell

ColumnLayout {
  id: root

  property string label: ""
  property var model: []
  // While a password prompt is open, we freeze the displayed model to avoid
  // frequent scan updates recreating items and clearing the TextInput.
  property var cachedModel: []
  readonly property var displayModel: (passwordSsid && passwordSsid.length > 0) ? cachedModel : model
  property string passwordSsid: ""
  property string expandedSsid: ""
  // Currently expanded info panel for a connected SSID
  property string infoSsid: ""
  // Local layout toggle for details: true = grid (2 cols), false = rows (1 col)
  property bool detailsGrid: true

  property string editingDnsIface: ""
  property string dnsInput: ""

  signal passwordRequested(string ssid)
  signal passwordSubmitted(string ssid, string password)
  signal passwordCancelled
  signal forgetRequested(string ssid)
  signal forgetConfirmed(string ssid)
  signal forgetCancelled
  signal dnsEditRequested(string iface, string currentDns)
  signal dnsEditCancelled()
  signal dnsEditSaved(string iface, string dns)

  onPasswordSsidChanged: {
    if (passwordSsid && passwordSsid.length > 0) {
      // Freeze current list ordering/content while entering password
      try {
        // Deep copy to decouple from live updates
        cachedModel = JSON.parse(JSON.stringify(model));
      } catch (e) {
        // Fallback to shallow copy
        cachedModel = model.slice ? model.slice() : model;
      }
    } else {
      // Clear freeze when password box is closed
      cachedModel = [];
    }
  }

  spacing: Style.appearance.spacing.normal
  visible: root.model.length > 0

  IText {
    text: root.label
    pointSize: Style.appearance.font.size.normal
    color: ThemeService.palette.mSecondary
    font.weight: Font.DemiBold
    Layout.fillWidth: true
    visible: root.label !== "" && root.model.length > 0
    Layout.leftMargin: Style.appearance.spacing.small
  }

  Repeater {
    model: root.displayModel

    delegate: Rectangle {
      id: wifiItem
      required property var modelData

      Layout.fillWidth: true
      implicitHeight: netColumn.implicitHeight + (Style.appearance.spacing.normal * 2)
      radius: Settings.appearance.cornerRadius
      opacity: (NetworkService.disconnectingFrom === modelData.ssid || NetworkService.forgettingNetwork === modelData.ssid) ? 0.6 : 1.0
      color: modelData.connected ? Qt.rgba(ThemeService.palette.mPrimary.r, ThemeService.palette.mPrimary.g, ThemeService.palette.mPrimary.b, 0.08) : ThemeService.palette.mSurface
      border.width: 2
      border.color: modelData.connected ? ThemeService.palette.mPrimary : Qt.alpha(ThemeService.palette.mOutline, 0.4)

      Behavior on opacity {
        NumberAnimation { duration: 200 }
      }

      ColumnLayout {
        id: netColumn
        width: parent.width - (Style.appearance.spacing.normal * 2)
        x: Style.appearance.spacing.normal
        y: Style.appearance.spacing.normal
        spacing: Style.appearance.spacing.normal

        // Main row
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.appearance.spacing.normal

          IIcon {
            icon: NetworkService.signalIcon(modelData.signal, modelData.connected)
            pointSize: Style.appearance.font.size.large
            color: modelData.connected ? (NetworkService.internetConnectivity ? ThemeService.palette.mPrimary : ThemeService.palette.mError) : ThemeService.palette.mOnSurface
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            IText {
              text: modelData.ssid
              pointSize: Style.appearance.font.size.small
              font.weight: modelData.connected ? Font.DemiBold : Font.Medium
              color: ThemeService.palette.mOnSurface
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            RowLayout {
              spacing: Style.appearance.spacing.small

              IText {
                text: NetworkService.isSecured(modelData.security) ? modelData.security : "Open"
                pointSize: Style.appearance.font.size.smaller
                color: ThemeService.palette.mOnSurfaceVariant
              }

              IIcon {
                icon: "lock_open"
                pointSize: Style.appearance.font.size.smaller
                color: ThemeService.palette.mOnSurfaceVariant
                visible: !NetworkService.isSecured(modelData.security)
              }

              // Status badges
              Rectangle {
                visible: modelData.connected && NetworkService.disconnectingFrom !== modelData.ssid
                color: NetworkService.internetConnectivity ? ThemeService.palette.mPrimary : ThemeService.palette.mError
                radius: height * 0.5
                width: connectedText.implicitWidth + (Style.appearance.spacing.normal * 2)
                height: connectedText.implicitHeight + (Style.appearance.spacing.small)

                IText {
                  id: connectedText
                  anchors.centerIn: parent
                  text: NetworkService.internetConnectivity ? "Connected" : "Limited"
                  pointSize: Style.appearance.font.size.smaller
                  color: ThemeService.palette.mOnPrimary
                }
              }

              Rectangle {
                visible: NetworkService.disconnectingFrom === modelData.ssid
                color: ThemeService.palette.mError
                radius: height * 0.5
                width: disconnectingText.implicitWidth + (Style.appearance.spacing.normal * 2)
                height: disconnectingText.implicitHeight + (Style.appearance.spacing.small)

                IText {
                  id: disconnectingText
                  anchors.centerIn: parent
                  text: "Disconnecting"
                  pointSize: Style.appearance.font.size.smaller
                  color: ThemeService.palette.mOnPrimary
                }
              }

              Rectangle {
                visible: NetworkService.forgettingNetwork === modelData.ssid
                color: ThemeService.palette.mError
                radius: height * 0.5
                width: forgettingText.implicitWidth + (Style.appearance.spacing.normal * 2)
                height: forgettingText.implicitHeight + (Style.appearance.spacing.small)

                IText {
                  id: forgettingText
                  anchors.centerIn: parent
                  text: "Forgetting"
                  pointSize: Style.appearance.font.size.smaller
                  color: ThemeService.palette.mOnPrimary
                }
              }

              Rectangle {
                visible: modelData.cached && !modelData.connected && NetworkService.forgettingNetwork !== modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid
                color: "transparent"
                border.color: ThemeService.palette.mOutline
                border.width: 1
                radius: height * 0.5
                width: savedText.implicitWidth + (Style.appearance.spacing.normal * 2)
                height: savedText.implicitHeight + (Style.appearance.spacing.small)

                IText {
                  id: savedText
                  anchors.centerIn: parent
                  text: "Saved"
                  pointSize: Style.appearance.font.size.smaller
                  color: ThemeService.palette.mOnSurfaceVariant
                }
              }
            }
          }

          // Action area
          RowLayout {
            spacing: Style.appearance.spacing.normal

            IBusyIndicator {
              visible: NetworkService.connectingTo === modelData.ssid || NetworkService.disconnectingFrom === modelData.ssid || NetworkService.forgettingNetwork === modelData.ssid
              running: visible
              color: ThemeService.palette.mPrimary
              size: Style.appearance.widget.size * 0.5
            }

            // Info toggle for connected network
            IIconButton {
              visible: modelData.connected && NetworkService.disconnectingFrom !== modelData.ssid
              icon: "info"
              size: Style.appearance.widget.size * 0.7
              onClicked: {
                if (root.infoSsid === modelData.ssid) {
                  root.infoSsid = "";
                } else {
                  root.infoSsid = modelData.ssid;
                  NetworkService.refreshActiveWifiDetails();
                }
              }
            }

            IIconButton {
              visible: (modelData.existing || modelData.cached) && !modelData.connected && NetworkService.connectingTo !== modelData.ssid && NetworkService.forgettingNetwork !== modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid
              icon: "delete"
              size: Style.appearance.widget.size * 0.7
              onClicked: root.forgetRequested(modelData.ssid)
            }

            IButton {
              visible: !modelData.connected && NetworkService.connectingTo !== modelData.ssid && root.passwordSsid !== modelData.ssid && NetworkService.forgettingNetwork !== modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid
              text: (modelData.existing || modelData.cached || !NetworkService.isSecured(modelData.security)) ? "Connect" : "Password"
              outlined: true
              fontSize: Style.appearance.font.size.smaller
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
              visible: modelData.connected && NetworkService.disconnectingFrom !== modelData.ssid
              text: "Disconnect"
              outlined: true
              fontSize: Style.appearance.font.size.smaller
              backgroundColor: ThemeService.palette.mError
              onClicked: NetworkService.disconnect(modelData.ssid)
            }
          }
        }

        // Connection info details
        Rectangle {
          id: infoContainer
          visible: root.infoSsid === modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid && NetworkService.forgettingNetwork !== modelData.ssid
          Layout.fillWidth: true
          Layout.preferredHeight: visible ? infoGrid.implicitHeight + (Style.appearance.spacing.normal * 2) : 0
          clip: true
          color: ThemeService.palette.mSurfaceVariant
          radius: Settings.appearance.cornerRadius
          border.width: 1
          border.color: ThemeService.palette.mOutline
          
          Behavior on Layout.preferredHeight {
            IAnim { duration: 200 }
          }

          IIconButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.appearance.spacing.small
            icon: root.detailsGrid ? "view_list" : "grid_view"
            size: Style.appearance.widget.size * 0.6
            onClicked: root.detailsGrid = !root.detailsGrid
            z: 1
          }

          GridLayout {
            id: infoGrid
            anchors.fill: parent
            anchors.margins: Style.appearance.spacing.normal
            columns: root.detailsGrid ? 2 : 1
            columnSpacing: Style.appearance.spacing.normal
            rowSpacing: Style.appearance.spacing.small

            // Row 1: Interface | Band
            RowLayout {
              Layout.fillWidth: true
              spacing: Style.appearance.spacing.small
              IIcon {
                icon: "router"
                pointSize: Style.appearance.font.size.smaller
                color: ThemeService.palette.mOnSurface
              }
              IText {
                text: NetworkService.activeWifiIf || "-"
                pointSize: Style.appearance.font.size.smaller
                color: ThemeService.palette.mOnSurface
                Layout.fillWidth: true
                elide: Text.ElideRight
                
                MouseArea {
                  anchors.fill: parent
                  enabled: (NetworkService.activeWifiIf || "").length > 0
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    Quickshell.execDetached(["wl-copy", NetworkService.activeWifiIf]);
                    ToastService.showNotice("Wi-Fi", "Interface name copied", "wifi");
                  }
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.appearance.spacing.small
              IIcon {
                icon: "wifi"
                pointSize: Style.appearance.font.size.smaller
                color: ThemeService.palette.mOnSurface
              }
              IText {
                text: NetworkService.activeWifiDetails.band || "-"
                pointSize: Style.appearance.font.size.smaller
                color: ThemeService.palette.mOnSurface
                Layout.fillWidth: true
              }
            }

            // Row 2: Link Speed | IPv4
            RowLayout {
              Layout.fillWidth: true
              spacing: Style.appearance.spacing.small
              IIcon {
                icon: "speed"
                pointSize: Style.appearance.font.size.smaller
                color: ThemeService.palette.mOnSurface
              }
              IText {
                text: NetworkService.activeWifiDetails.rateShort || NetworkService.activeWifiDetails.rate || "-"
                pointSize: Style.appearance.font.size.smaller
                color: ThemeService.palette.mOnSurface
                Layout.fillWidth: true
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.appearance.spacing.small
              IIcon {
                icon: "lan"
                pointSize: Style.appearance.font.size.smaller
                color: ThemeService.palette.mOnSurface
              }
              IText {
                text: NetworkService.activeWifiDetails.ipv4 || "-"
                pointSize: Style.appearance.font.size.smaller
                color: ThemeService.palette.mOnSurface
                Layout.fillWidth: true
                elide: Text.ElideRight

                MouseArea {
                  anchors.fill: parent
                  enabled: (NetworkService.activeWifiDetails.ipv4 || "").length > 0
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    Quickshell.execDetached(["wl-copy", NetworkService.activeWifiDetails.ipv4]);
                    ToastService.showNotice("Wi-Fi", "IP address copied", "wifi");
                  }
                }
              }
            }

            // Row 3: Gateway | DNS
            RowLayout {
              Layout.fillWidth: true
              spacing: Style.appearance.spacing.small
              IIcon {
                icon: "router"
                pointSize: Style.appearance.font.size.smaller
                color: ThemeService.palette.mOnSurface
              }
              IText {
                text: NetworkService.activeWifiDetails.gateway4 || "-"
                pointSize: Style.appearance.font.size.smaller
                color: ThemeService.palette.mOnSurface
                Layout.fillWidth: true
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.appearance.spacing.small
              IIcon {
                icon: "dns"
                pointSize: Style.appearance.font.size.smaller
                color: ThemeService.palette.mOnSurface
              }
              
              IText {
                text: (root.infoSsid === modelData.ssid ? NetworkService.activeWifiDetails.dns : "") || "-"
                color: ThemeService.palette.mOnSurface
                pointSize: Style.appearance.font.size.smaller
                Layout.fillWidth: true
                elide: Text.ElideRight
              }

              IIconButton {
                visible: modelData.connected && root.infoSsid === modelData.ssid
                icon: "edit"
                size: 20
                onClicked: {
                  if (editingDnsIface === NetworkService.activeWifiIf) {
                    root.dnsEditCancelled();
                  } else {
                    root.dnsEditRequested(NetworkService.activeWifiIf, NetworkService.activeWifiDetails.dns || "");
                  }
                }
              }
            }
          }
        }

        // DNS Editor
        Rectangle {
          id: dnsContainer
          Layout.fillWidth: true
          Layout.preferredHeight: (root.infoSsid === modelData.ssid && editingDnsIface === NetworkService.activeWifiIf) ? implicitHeight : 0
          implicitHeight: dnsRow.implicitHeight + (Style.appearance.spacing.normal * 2)
          visible: Layout.preferredHeight > 0
          clip: true
          color: ThemeService.palette.mSurfaceVariant
          border.color: ThemeService.palette.mOutline
          border.width: 1
          radius: Settings.appearance.cornerRadius

          Behavior on Layout.preferredHeight {
            IAnim { duration: 200 }
          }

          RowLayout {
            id: dnsRow
            anchors.fill: parent
            anchors.margins: Style.appearance.spacing.normal
            spacing: Style.appearance.spacing.normal

            Rectangle {
              Layout.fillWidth: true
              Layout.fillHeight: true
              radius: Settings.appearance.cornerRadius
              color: ThemeService.palette.mSurface
              border.color: dnsInputRef.activeFocus ? ThemeService.palette.mPrimary : ThemeService.palette.mOutline
              border.width: 1

              TextInput {
                id: dnsInputRef
                anchors.fill: parent
                anchors.margins: Style.appearance.spacing.small
                text: dnsInput
                font.pointSize: Style.appearance.font.size.small
                color: ThemeService.palette.mOnSurface
                selectByMouse: true
                focus: visible
                verticalAlignment: TextInput.AlignVCenter
                onTextChanged: dnsInput = text
                onVisibleChanged: if (visible) forceActiveFocus()
                onAccepted: {
                  if (text && !NetworkService.connecting) {
                    root.dnsEditSaved(editingDnsIface, dnsInput);
                  }
                }

                IText {
                  visible: parent.text.length === 0
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Enter DNS (comma separated)"
                  color: ThemeService.palette.mOnSurfaceVariant
                  pointSize: Style.appearance.font.size.small
                }
              }
            }

            IButton {
              text: "Save"
              fontSize: Style.appearance.font.size.smaller
              enabled: dnsInput.length > 0
              onClicked: root.dnsEditSaved(editingDnsIface, dnsInput)
            }

            IIconButton {
              icon: "close"
              size: Style.appearance.widget.size * 0.8
              onClicked: root.dnsEditCancelled()
            }
          }
        }

        // Password input
        Rectangle {
          id: passwordContainer
          Layout.fillWidth: true
          Layout.preferredHeight: root.passwordSsid === modelData.ssid ? implicitHeight : 0
          implicitHeight: passwordRow.implicitHeight + (Style.appearance.spacing.normal * 2)
          visible: Layout.preferredHeight > 0
          clip: true
          color: ThemeService.palette.mSurfaceVariant
          border.color: ThemeService.palette.mOutline
          border.width: 1
          radius: Settings.appearance.cornerRadius

          Behavior on Layout.preferredHeight {
            IAnim { duration: 200 }
          }

          property string passwordInput: ""

          RowLayout {
            id: passwordRow
            anchors.fill: parent
            anchors.margins: Style.appearance.spacing.normal
            spacing: Style.appearance.spacing.normal

            Rectangle {
              Layout.fillWidth: true
              Layout.fillHeight: true
              radius: Settings.appearance.cornerRadius
              color: ThemeService.palette.mSurface
              border.color: pwdInput.activeFocus ? ThemeService.palette.mSecondary : ThemeService.palette.mOutline
              border.width: 1

              TextInput {
                id: pwdInput
                anchors.fill: parent
                anchors.margins: Style.appearance.spacing.small
                text: passwordContainer.passwordInput
                font.pointSize: Style.appearance.font.size.small
                color: ThemeService.palette.mOnSurface
                echoMode: TextInput.Password
                selectByMouse: true
                focus: visible
                passwordCharacter: "●"
                verticalAlignment: TextInput.AlignVCenter
                onTextChanged: passwordContainer.passwordInput = text
                onVisibleChanged: if (visible) forceActiveFocus()
                onAccepted: {
                  if (text && !NetworkService.connecting) {
                    root.passwordSubmitted(modelData.ssid, text);
                  }
                }

                IText {
                  visible: parent.text.length === 0
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Enter password"
                  color: ThemeService.palette.mOnSurfaceVariant
                  pointSize: Style.appearance.font.size.small
                }
              }
            }

            IButton {
              text: "Connect"
              fontSize: Style.appearance.font.size.smaller
              enabled: passwordContainer.passwordInput.length > 0 && !NetworkService.connecting
              outlined: true
              onClicked: root.passwordSubmitted(modelData.ssid, passwordContainer.passwordInput)
            }

            IIconButton {
              icon: "close"
              size: Style.appearance.widget.size * 0.8
              onClicked: root.passwordCancelled()
            }
          }
        }

        // Forget network
        Rectangle {
          id: forgetContainer
          Layout.fillWidth: true
          Layout.preferredHeight: root.expandedSsid === modelData.ssid ? implicitHeight : 0
          implicitHeight: forgetRow.implicitHeight + (Style.appearance.spacing.normal * 2)
          visible: Layout.preferredHeight > 0
          clip: true
          color: ThemeService.palette.mSurfaceVariant
          radius: Settings.appearance.cornerRadius
          border.width: 1
          border.color: ThemeService.palette.mOutline

          Behavior on Layout.preferredHeight {
            IAnim { duration: 200 }
          }

          RowLayout {
            id: forgetRow
            anchors.fill: parent
            anchors.margins: Style.appearance.spacing.normal
            spacing: Style.appearance.spacing.normal

            RowLayout {
              IIcon {
                icon: "delete"
                pointSize: Style.appearance.font.size.large
                color: ThemeService.palette.mError
              }

              IText {
                text: "Forget this network?"
                pointSize: Style.appearance.font.size.small
                color: ThemeService.palette.mError
                Layout.fillWidth: true
              }
            }

            IButton {
              id: forgetButton
              text: "Forget"
              fontSize: Style.appearance.font.size.smaller
              backgroundColor: ThemeService.palette.mError
              onClicked: root.forgetConfirmed(modelData.ssid)
            }

            IIconButton {
              icon: "close"
              size: Style.appearance.widget.size * 0.8
              onClicked: root.forgetCancelled()
            }
          }
        }
      }
    }
  }
}
