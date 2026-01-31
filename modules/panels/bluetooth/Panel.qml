pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.common
import qs.modules.panels
import qs.services
import qs.widgets

SmartPanel {
  id: root

  panelContent: Item {
    readonly property real contentPreferredWidth: Style.bar.bluetoothWidth
    readonly property real contentPreferredHeight: mainColumn.implicitHeight + Style.padding.small * 2

    anchors.fill: parent

    ColumnLayout {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: Style.padding.small
      spacing: Style.spacing.small

      IBox {
        Layout.fillWidth: true
        Layout.preferredHeight: headerRow.implicitHeight + Style.padding.small

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.padding.small
          spacing: Style.spacing.small

          IIcon {
            icon: BluetoothService.enabled ? "bluetooth" : "bluetooth_disabled"
            color: BluetoothService.enabled ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurfaceVariant
          }

          IText {
            text: "Bluetooth"
            color: ThemeService.palette.mOnSurface
            Layout.fillWidth: true
          }

          IToggle {
            checked: BluetoothService.enabled
            onToggled: checked => {
              BluetoothService.setBluetoothEnabled(checked);
            }
          }

          IIconButton {
            icon: Settings.network.bluetoothHideUnnamedDevices ? "filter_alt" : "filter_alt_off"
            size: Style.widget.size * 0.8
            onClicked: {
              Settings.network.bluetoothHideUnnamedDevices = !Settings.network.bluetoothHideUnnamedDevices;
            }
          }

          IIconButton {
            enabled: BluetoothService.enabled
            icon: BluetoothService.discoverable ? "cast" : "cast_pause"
            size: Style.widget.size * 0.8
            onClicked: {
              BluetoothService.setDiscoverable(!BluetoothService.discoverable);
            }
          }

          IIconButton {
            enabled: BluetoothService.enabled
            icon: BluetoothService.scanningActive ? "stop" : "refresh"
            size: Style.widget.size * 0.8
            onClicked: BluetoothService.toggleDiscovery()
          }

          IIconButton {
            icon: "close"
            size: Style.widget.size * 0.8
            onClicked: root.close()
          }
        }
      }

      IDivider {
        Layout.fillWidth: true
      }

      IFlickable {
        id: devicesFlickable
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(380, devicesList.implicitHeight)
        contentHeight: devicesList.implicitHeight
        clip: true

        ColumnLayout {
          id: devicesList
          width: parent.width
          spacing: Style.spacing.small

          readonly property bool isBluetoothEnabled: BluetoothService.adapter?.enabled ?? false

          property string selectedDeviceKey: ""
          property string infoDeviceKey: ""
          property string expandedDeviceKey: ""

          readonly property var allDevices: {
            if (!isBluetoothEnabled || !BluetoothService.adapter?.devices) {
              return [];
            }

            const adapterDevices = BluetoothService.adapter.devices;
            let devices = adapterDevices.values.filter(function (dev) {
              return dev && !dev.blocked;
            });

            // Filter unnamed/junk if enabled
            if (Settings.network.bluetoothHideUnnamedDevices) {
              devices = devices.filter(function (dev) {
                // Extract display name
                const deviceName = dev?.name || dev?.deviceName || "";
                const trimmedName = String(deviceName).trim();

                // 1) Hide empty or whitespace-only
                if (trimmedName.length === 0)
                  return false;

                // 2) Hide common placeholders
                const lowerName = trimmedName.toLowerCase();
                if (lowerName === "unknown" || lowerName === "unnamed" || lowerName === "n/a" || lowerName === "na") {
                  return false;
                }

                // 3) Hide if the name equals the device address (ignoring separators)
                const addr = dev?.address || dev?.bdaddr || dev?.mac || "";
                if (addr.length > 0) {
                  const normName = trimmedName.toLowerCase().replace(/[^0-9a-z]/g, "");
                  const normAddr = String(addr).toLowerCase().replace(/[^0-9a-z]/g, "");
                  if (normName.length > 0 && normName === normAddr)
                    return false;
                }

                // 4) Hide address-like strings using regex patterns
                const patterns = [/^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/     // 00:11:22:33:44:55
                  , /^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$/     // 00-11-22-33-44-55
                  , /^([0-9A-Za-z]{2}-){5}[0-9A-Za-z]{2}$/     // alnum pairs
                  , /^[0-9A-Fa-f]{4}\.[0-9A-Fa-f]{4}\.[0-9A-Fa-f]{4}$/ // 0011.2233.4455
                  , /^[0-9A-Fa-f]{12}$/                          // 001122334455
                ];

                for (let i = 0; i < patterns.length; i++) {
                  if (patterns[i].test(trimmedName))
                    return false;
                }

                return true;
              });
            }

            // Dedupe
            const dedupeFunc = BluetoothService.dedupeDevices;
            if (dedupeFunc) {
              devices = dedupeFunc(devices);
            }

            // Sort: Connected > Paired/Trusted > Name
            devices.sort(function (a, b) {
              // 1. Connected
              const aConn = a.connected && a.state !== BluetoothDeviceState.Disconnecting;
              const bConn = b.connected && b.state !== BluetoothDeviceState.Disconnecting;
              if (aConn !== bConn)
                return bConn - aConn;

              // 2. Paired/Trusted
              const aPaired = a.paired || a.trusted;
              const bPaired = b.paired || b.trusted;
              if (aPaired !== bPaired)
                return bPaired - aPaired;

              // 3. Name
              const nameA = a.name || a.deviceName || "";
              const nameB = b.name || b.deviceName || "";
              return nameA.localeCompare(nameB);
            });

            return devices;
          }

          readonly property bool showNoDevices: isBluetoothEnabled && allDevices.length === 0

          // Bluetooth disabled state
          IIcon {
            visible: !devicesList.isBluetoothEnabled
            icon: "bluetooth_disabled"
            font.pointSize: Style.font.size.extraLarge
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          IText {
            visible: !devicesList.isBluetoothEnabled
            text: "Bluetooth is disabled"
            font.pointSize: Style.font.size.large
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          // No devices found state
          IIcon {
            visible: devicesList.showNoDevices
            icon: "bluetooth"
            font.pointSize: Style.font.size.extraLarge
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          IText {
            visible: devicesList.showNoDevices
            text: "No devices found"
            font.pointSize: Style.font.size.large
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          IButton {
            visible: devicesList.showNoDevices
            text: "Refresh"
            icon: "refresh"
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
              BluetoothService.toggleDiscovery();
            }
          }

          // Unified Devices List
          BluetoothDevicesList {
            visible: devicesList.allDevices.length > 0
            model: devicesList.allDevices
            Layout.fillWidth: true

            selectedDeviceKey: devicesList.selectedDeviceKey
            infoDeviceKey: devicesList.infoDeviceKey
            expandedDeviceKey: devicesList.expandedDeviceKey

            onSelectedRequested: key => {
              devicesList.selectedDeviceKey = (devicesList.selectedDeviceKey === key ? "" : key);
            }
            onInfoRequested: key => {
              devicesList.infoDeviceKey = (devicesList.infoDeviceKey === key ? "" : key);
            }
            onForgetRequested: key => {
              devicesList.expandedDeviceKey = (devicesList.expandedDeviceKey === key ? "" : key);
            }

            onForgetConfirmed: key => {
              const adapterDevices = BluetoothService.adapter.devices;
              const deviceKeyFunc = BluetoothService.deviceKey;
              const dev = adapterDevices.values.find(function (d) {
                return deviceKeyFunc(d) === key;
              });
              if (dev)
                BluetoothService.unpairDevice(dev);
              devicesList.expandedDeviceKey = "";
            }
            onForgetCancelled: {
              devicesList.expandedDeviceKey = "";
            }
          }
        }
      }
    }
  }
}
