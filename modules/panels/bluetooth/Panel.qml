pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.commons
import qs.services
import qs.widgets
import ".."

BarPanel {
  id: root

  contentComponent: Item {
    id: content
    implicitWidth: 400
    implicitHeight: mainColumn.implicitHeight + root.padding * 2

    ColumnLayout {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: root.padding
      spacing: root.spacing

      IBox {
        id: headerBox
        Layout.fillWidth: true

        implicitHeight: headerRow.implicitHeight + root.padding * 2

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.leftMargin: root.padding
          anchors.rightMargin: root.padding
          spacing: root.spacing

          IIcon {
            icon: "bluetooth"
            color: ThemeService.palette.mPrimary
          }

          IText {
            text: "Bluetooth"
            pointSize: Style.appearance.font.size.larger
            color: ThemeService.palette.mOnSurface
            Layout.fillWidth: true
          }

          ISwitch {
            id: bluetoothSwitch
            checked: BluetoothService.enabled
            onToggled: {
              BluetoothService.setBluetoothEnabled(!BluetoothService.enabled);
            }
          }

          IIconButton {
            enabled: BluetoothService.enabled
            icon: BluetoothService.adapter && BluetoothService.adapter.discovering ? "stop" : "refresh"
            size: Style.appearance.widget.size * 0.8
            onClicked: {
              if (BluetoothService.adapter)
                BluetoothService.adapter.discovering = !BluetoothService.adapter.discovering;
            }
          }

          IIconButton {
            enabled: BluetoothService.enabled
            icon: "close"
            size: Style.appearance.widget.size * 0.8
            onClicked: root.close()
          }
        }
      }

      IBox {
        id: disabledBox
        Layout.fillWidth: true
        Layout.preferredHeight: 200
        visible: !(BluetoothService.adapter && BluetoothService.adapter.enabled)

        ColumnLayout {
          anchors.centerIn: parent
          spacing: root.spacing

          IIcon {
            icon: "bluetooth_disabled"
            pointSize: 48
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          IText {
            text: "Bluetooth is disabled"
            pointSize: Style.appearance.font.size.large
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          IText {
            text: "Enable Bluetooth to see available devices."
            pointSize: Style.appearance.font.size.small
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }
        }
      }

      Item {
        id: devicesBox
        Layout.fillWidth: true
        visible: BluetoothService.adapter && BluetoothService.adapter.enabled

        implicitHeight: Math.min(devicesColumn.implicitHeight + root.padding * 2, 380)

        IFlickable {
          anchors.fill: parent
          clip: true

          contentWidth: width
          contentHeight: devicesColumn.implicitHeight
          boundsBehavior: Flickable.StopAtBounds

          ColumnLayout {
            id: devicesColumn
            width: parent.width
            spacing: root.spacing

            // Connected devices
            DevicesList {
              label: "Connected devices"
              property var items: {
                if (!BluetoothService.adapter || !Bluetooth.devices)
                  return [];
                const filtered = Bluetooth.devices.values.filter(dev => dev && !dev.blocked && dev.connected);
                return BluetoothService.sortDevices(filtered);
              }
              model: items
              visible: items.length > 0
              Layout.fillWidth: true
            }

            // Known devices
            DevicesList {
              label: "Known devices"
              property var items: {
                if (!BluetoothService.adapter || !Bluetooth.devices)
                  return [];
                const filtered = Bluetooth.devices.values.filter(dev => dev && !dev.blocked && !dev.connected && (dev.paired || dev.trusted));
                return BluetoothService.sortDevices(filtered);
              }
              model: items
              visible: items.length > 0
              Layout.fillWidth: true
            }

            // Available devices
            DevicesList {
              label: "Available devices"
              property var items: {
                if (!BluetoothService.adapter || !Bluetooth.devices)
                  return [];
                const filtered = Bluetooth.devices.values.filter(dev => dev && !dev.blocked && !dev.paired && !dev.trusted);
                return BluetoothService.sortDevices(filtered);
              }
              model: items
              visible: items.length > 0
              Layout.fillWidth: true
            }

            // Fallback - No devices, scanning
            IBox {
              Layout.fillWidth: true
              Layout.preferredHeight: columnScanning.implicitHeight + root.padding * 2
              visible: {
                if (!BluetoothService.adapter || !BluetoothService.adapter.discovering || !Bluetooth.devices) {
                  return false;
                }

                var availableCount = Bluetooth.devices.values.filter(dev => {
                  return dev && !dev.paired && !dev.pairing && !dev.blocked && (dev.signalStrength === undefined || dev.signalStrength > 0);
                }).length;
                return (availableCount === 0);
              }

              ColumnLayout {
                id: columnScanning
                anchors.fill: parent
                anchors.margins: root.padding

                spacing: root.spacing

                RowLayout {
                  Layout.alignment: Qt.AlignHCenter
                  spacing: root.spacing

                  IIcon {
                    icon: "refresh"
                    pointSize: Style.appearance.font.size.extraLarge * 1.5
                    color: ThemeService.palette.mPrimary

                    RotationAnimation on rotation {
                      running: true
                      loops: Animation.Infinite
                      from: 0
                      to: 360
                      duration: Style.appearance.anim.durations.large * 4
                    }
                  }

                  IText {
                    text: "Scanning for devices..."
                    pointSize: Style.appearance.font.size.large
                    color: ThemeService.palette.mOnSurface
                  }
                }

                IText {
                  text: "Make sure your device is in pairing mode."
                  color: ThemeService.palette.mOnSurfaceVariant
                  horizontalAlignment: Text.AlignHCenter
                  Layout.fillWidth: true
                  wrapMode: Text.WordWrap
                }
              }
            }
          }
        }
      }
    }
  }
}
