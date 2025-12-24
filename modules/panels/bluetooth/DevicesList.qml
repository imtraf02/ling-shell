pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.config
import qs.commons
import qs.services
import qs.widgets

IBox {
  id: root

  property string label: ""
  property var model: ({})

  readonly property real padding: Config.appearance.padding.normal
  readonly property real spacing: Config.appearance.spacing.small

  Layout.fillWidth: true
  Layout.preferredHeight: column.implicitHeight + root.padding * 2

  ColumnLayout {
    id: column
    anchors.fill: parent
    anchors.margins: root.padding
    spacing: root.spacing

    IText {
      text: root.label
      pointSize: Config.appearance.font.size.normal
      color: ThemeService.palette.mSecondary
      visible: root.model.length > 0
      Layout.fillWidth: true
      Layout.leftMargin: root.padding
    }

    Repeater {
      id: deviceList
      Layout.fillWidth: true
      model: root.model
      visible: BluetoothService.adapter && BluetoothService.adapter.enabled

      Rectangle {
        id: device

        required property var modelData

        readonly property bool canConnect: BluetoothService.canConnect(modelData)
        readonly property bool canDisconnect: BluetoothService.canDisconnect(modelData)
        readonly property bool isBusy: BluetoothService.isDeviceBusy(modelData)

        function getContentColor(defaultColor = ThemeService.palette.mOnSurface) {
          if (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting)
            return ThemeService.palette.mPrimary;
          if (modelData.blocked)
            return ThemeService.palette.mError;
          return defaultColor;
        }

        Layout.fillWidth: true
        Layout.preferredHeight: deviceLayout.implicitHeight + root.padding * 2
        radius: Settings.appearance.cornerRadius
        color: ThemeService.palette.mSurface
        border.width: 1
        border.color: getContentColor(ThemeService.palette.mOutline)

        RowLayout {
          id: deviceLayout
          anchors.fill: parent
          anchors.margins: root.padding
          spacing: root.spacing
          Layout.alignment: Qt.AlignVCenter

          IIcon {
            icon: BluetoothService.getDeviceIcon(device.modelData)
            pointSize: Config.appearance.font.size.large
            color: device.getContentColor(ThemeService.palette.mOnSurface)
            Layout.alignment: Qt.AlignVCenter
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: root.spacing

            IText {
              text: device.modelData.name || device.modelData.deviceName
              pointSize: Config.appearance.font.size.large
              elide: Text.ElideRight
              color: device.getContentColor(ThemeService.palette.mOnSurface)
              Layout.fillWidth: true
            }

            IText {
              text: BluetoothService.getStatusString(device.modelData)
              visible: text !== ""
              pointSize: Config.appearance.font.size.small
              color: device.getContentColor(ThemeService.palette.mOnSurfaceVariant)
            }

            RowLayout {
              visible: device.modelData.signalStrength !== undefined
              Layout.fillWidth: true
              spacing: root.spacing

              IText {
                text: BluetoothService.getSignalStrength(device.modelData)
                pointSize: Config.appearance.font.size.small
                color: device.getContentColor(ThemeService.palette.mOnSurfaceVariant)
              }

              IIcon {
                visible: device.modelData.signalStrength > 0 && !device.modelData.pairing && !device.modelData.blocked
                icon: BluetoothService.getSignalIcon(device.modelData)
                pointSize: Config.appearance.font.size.small
                color: device.getContentColor(ThemeService.palette.mOnSurface)
              }

              IText {
                visible: device.modelData.signalStrength > 0 && !device.modelData.pairing && !device.modelData.blocked
                text: (device.modelData.signalStrength > 0) ? device.modelData.signalStrength + "%" : ""
                pointSize: Config.appearance.font.size.small
                color: device.getContentColor(ThemeService.palette.mOnSurface)
              }
            }

            IText {
              visible: device.modelData.batteryAvailable
              text: BluetoothService.getBattery(device.modelData)
              pointSize: Config.appearance.font.size.small
              color: device.getContentColor(ThemeService.palette.mOnSurfaceVariant)
            }
          }

          Item {
            Layout.fillWidth: true
          }

          IButton {
            id: button
            visible: device.modelData.state !== BluetoothDeviceState.Connecting
            enabled: (device.canConnect || device.canDisconnect) && !device.isBusy
            outlined: !button.hovered

            fontSize: Config.appearance.font.size.small
            fontWeight: Font.Medium

            backgroundColor: device.canDisconnect && !device.isBusy ? ThemeService.palette.mError : ThemeService.palette.mPrimary

            text: {
              if (device.modelData.pairing)
                return "Pairing…";
              if (device.modelData.blocked)
                return "Blocked";
              if (device.modelData.connected)
                return "Disconnect";
              return "Connect";
            }

            icon: device.isBusy ? "busy" : null

            onClicked: {
              if (device.modelData.connected)
                BluetoothService.disconnectDevice(device.modelData);
              else
                BluetoothService.connectDeviceWithTrust(device.modelData);
            }

            onRightClicked: BluetoothService.forgetDevice(device.modelData)
          }
        }
      }
    }
  }
}
