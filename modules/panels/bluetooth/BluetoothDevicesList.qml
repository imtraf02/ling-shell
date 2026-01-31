pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.common
import qs.services
import qs.widgets
import qs.utils

ColumnLayout {
  id: root

  property var model: []
  property string selectedDeviceKey: ""
  property string infoDeviceKey: ""
  property string expandedDeviceKey: ""

  signal selectedRequested(string key)
  signal infoRequested(string key)
  signal forgetRequested(string key)
  signal forgetConfirmed(string key)
  signal forgetCancelled

  spacing: Style.spacing.small

  Repeater {
    model: root.model

    delegate: IBox {
      id: deviceItem
      required property var modelData
      required property int index

      Layout.fillWidth: true
      implicitHeight: deviceColumn.implicitHeight + Style.padding.small * 2

      readonly property string deviceKey: BluetoothService.deviceKey(modelData)
      readonly property bool isConnected: modelData.connected && modelData.state !== BluetoothDeviceState.Disconnecting
      readonly property bool isPairing: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting
      readonly property bool isDisconnecting: modelData.blocked || modelData.state === BluetoothDeviceState.Disconnecting
      readonly property bool isHovered: itemMouseArea.containsMouse
      readonly property bool isSelected: root.selectedDeviceKey === deviceKey
      readonly property bool showInfo: root.infoDeviceKey === deviceKey
      readonly property bool showForget: root.expandedDeviceKey === deviceKey
      readonly property bool isPairedOrTrusted: modelData.paired || modelData.trusted
      readonly property int batteryPercent: BluetoothService.getBatteryPercent(modelData) ?? 0
      readonly property string deviceDisplayName: modelData.name || modelData.deviceName || "Unknown Device"

      opacity: isDisconnecting ? 0.6 : 1.0
      color: isConnected ? Qt.alpha(ThemeService.palette.mPrimary, 0.08) : (isHovered ? ThemeService.palette.mSurfaceVariant : ThemeService.palette.mSurface)

      Behavior on color {
        ICAnim {}
      }

      MouseArea {
        id: itemMouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: false  // Disable click on whole area
      }

      ColumnLayout {
        id: deviceColumn
        anchors.fill: parent
        anchors.margins: Style.padding.small
        spacing: Style.spacing.small

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.spacing.small

          IIcon {
            icon: Icons.getBluetoothDeviceIcon(deviceItem.modelData)
            font.pointSize: Style.font.size.large
            color: deviceItem.isConnected ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurface
            Layout.alignment: Qt.AlignVCenter
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            IText {
              text: deviceItem.deviceDisplayName
              font.pointSize: Style.font.size.small
              font.weight: deviceItem.isConnected ? Font.Bold : Font.Medium
              color: ThemeService.palette.mOnSurface
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            // Status text
            IText {
              visible: deviceItem.isPairing || deviceItem.isDisconnecting
              text: deviceItem.isPairing ? "Pairing..." : "Disconnecting..."
              font.pointSize: Style.font.size.small
              color: ThemeService.palette.mOnSurfaceVariant
            }

            // Battery indicator
            RowLayout {
              visible: deviceItem.modelData.batteryAvailable
              spacing: Style.spacing.smaller

              IIcon {
                icon: Icons.getBatteryIcon(deviceItem.batteryPercent, false, true)
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurfaceVariant
              }

              IText {
                text: deviceItem.batteryPercent + "%"
                font.pointSize: Style.font.size.small
                color: ThemeService.palette.mOnSurfaceVariant
              }
            }
          }

          // Spacer
          Item {
            Layout.fillWidth: true
          }

          // Actions row (Info + Forget + Connect/Disconnect)
          RowLayout {
            spacing: Style.spacing.small

            // Info button (for connected or paired devices)
            IIconButton {
              visible: deviceItem.isConnected || deviceItem.isPairedOrTrusted
              icon: "info"
              size: Style.widget.size * 0.8
              onClicked: {
                root.infoRequested(deviceItem.deviceKey);
              }
            }

            // Forget button (for paired but not connected devices)
            IIconButton {
              visible: deviceItem.isPairedOrTrusted && !deviceItem.isConnected
              icon: "delete"
              size: Style.widget.size * 0.8
              onClicked: {
                root.forgetRequested(deviceItem.deviceKey);
              }
            }

            // Main CTA button
            IButton {
              visible: modelData.state !== BluetoothDeviceState.Connecting
              text: {
                if (deviceItem.isPairing)
                  return "Pairing...";
                if (deviceItem.isConnected)
                  return "Disconnect";
                if (BluetoothService.canPair(deviceItem.modelData))
                  return "Pair";
                return "Connect";
              }
              fontSize: Style.font.size.small
              outlined: !deviceItem.isConnected
              backgroundColor: deviceItem.isConnected ? ThemeService.palette.mError : ThemeService.palette.mPrimary
              enabled: !BluetoothService.isDeviceBusy(deviceItem.modelData)
              onClicked: {
                const device = deviceItem.modelData;
                if (deviceItem.isConnected) {
                  BluetoothService.disconnectDevice(device);
                } else if (BluetoothService.canPair(device)) {
                  BluetoothService.pairDevice(device);
                } else {
                  BluetoothService.connectDeviceWithTrust(device);
                }
              }
            }
          }
        }

        // Info details (expandable)
        Rectangle {
          visible: deviceItem.showInfo
          Layout.fillWidth: true
          color: ThemeService.palette.mSurfaceVariant
          radius: Style.rounding.small
          border.width: 1
          border.color: ThemeService.palette.mOutline
          implicitHeight: infoGrid.implicitHeight + Style.padding.small * 2
          clip: true

          GridLayout {
            id: infoGrid
            anchors.fill: parent
            anchors.margins: Style.padding.small
            columns: 2
            columnSpacing: Style.spacing.small
            rowSpacing: Style.spacing.smaller

            IText {
              text: "Address:"
              color: ThemeService.palette.mOnSurfaceVariant
              font.pointSize: Style.font.size.small
            }
            IText {
              text: deviceItem.modelData.address || "-"
              color: ThemeService.palette.mOnSurface
              font.pointSize: Style.font.size.small
              Layout.fillWidth: true
            }

            IText {
              text: "Trusted:"
              color: ThemeService.palette.mOnSurfaceVariant
              font.pointSize: Style.font.size.small
            }
            IText {
              text: deviceItem.modelData.trusted ? "Yes" : "No"
              color: ThemeService.palette.mOnSurface
              font.pointSize: Style.font.size.small
              Layout.fillWidth: true
            }

            IText {
              text: "Blocked:"
              color: ThemeService.palette.mOnSurfaceVariant
              font.pointSize: Style.font.size.small
            }
            IText {
              text: deviceItem.modelData.blocked ? "Yes" : "No"
              color: ThemeService.palette.mOnSurface
              font.pointSize: Style.font.size.small
              Layout.fillWidth: true
            }

            IText {
              text: "MAC:"
              color: ThemeService.palette.mOnSurfaceVariant
              font.pointSize: Style.font.size.small
            }
            IText {
              text: deviceItem.deviceKey || "-"
              color: ThemeService.palette.mOnSurface
              font.pointSize: Style.font.size.small
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
          }
        }

        // Forget confirmation
        Rectangle {
          visible: deviceItem.showForget
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

            IIcon {
              icon: "delete"
              color: ThemeService.palette.mError
            }

            IText {
              text: "Forget this device?"
              color: ThemeService.palette.mError
              font.pointSize: Style.font.size.small
              Layout.fillWidth: true
            }

            IButton {
              text: "Forget"
              fontSize: Style.font.size.small
              backgroundColor: ThemeService.palette.mError
              onClicked: {
                root.forgetConfirmed(deviceItem.deviceKey);
              }
            }

            IIconButton {
              icon: "close"
              size: Style.widget.size * 0.8
              onClicked: {
                root.forgetCancelled();
              }
            }
          }
        }
      }
    }
  }
}
