import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.commons
import qs.widgets
import qs.services

ColumnLayout {
  id: root

  readonly property int padding: Style.appearance.padding.normal
  spacing: Style.appearance.spacing.larger

  ILabel {
    label: ""
    description: "Manage Wi-Fi and Bluetooth connections."
  }

  IToggle {
    label: "Enable Wi-Fi"
    checked: Settings.network.wifiEnabled
    onToggled: checked => NetworkService.setWifiEnabled(checked)
  }

  IToggle {
    label: "Enable Bluetooth"
    checked: BluetoothService.enabled
    onToggled: checked => BluetoothService.setBluetoothEnabled(checked)
  }

  IDivider {
    Layout.fillWidth: true
    Layout.topMargin: root.padding
    Layout.bottomMargin: root.padding
  }
}
