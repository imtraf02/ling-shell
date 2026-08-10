import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

ColumnLayout {
  spacing: Style.spacing.normal
  SettingsPage {
    title: "Network & Bluetooth"
    description: "Connectivity defaults and device-discovery behavior."
    icon: "network_wifi"
    sectionId: "network"
    SettingsCardGrid {
      id: grid
      SettingsCard {
        title: "Connection status"
        description: "Live state from the current NetworkManager snapshot."
        icon: "wifi"
        Layout.columnSpan: grid.columns
        IBox {
          Layout.fillWidth: true; implicitHeight: 62; color: ThemeService.palette.mSurfaceVariant
          RowLayout {
            anchors.fill: parent
            anchors.margins: Style.padding.normal
            IIcon { icon: NetworkService.ethernetConnected ? "lan" : (Settings.network.wifiEnabled ? "network_wifi" : "signal_wifi_off"); color: ThemeService.palette.mPrimary; font.pointSize: Style.font.size.extraLarge }
            IText { Layout.fillWidth: true; text: NetworkService.ethernetConnected ? "Ethernet connected" : (Settings.network.wifiEnabled ? "Wi-Fi enabled" : "Wi-Fi disabled"); font.weight: Font.Medium }
          }
        }
      }
      SettingsCard {
        title: "Wi-Fi"
        description: "Default behavior for the network panel."
        icon: "wifi"
        IToggle { label: "Wi-Fi enabled"; checked: Settings.network.wifiEnabled; onToggled: checked => NetworkService.setWifiEnabled(checked) }
        SettingsChoiceGroup { label: "Network panel default"; currentKey: Settings.network.networkPanelView; model: [{ key: "wifi", name: "Wi-Fi", icon: "wifi" }, { key: "ethernet", name: "Ethernet", icon: "lan" }]; onSelected: key => Settings.network.networkPanelView = key }
        SettingsChoiceGroup { label: "Network details view"; currentKey: Settings.network.wifiDetailsViewMode; model: [{ key: "grid", name: "Grid", icon: "grid_view" }, { key: "list", name: "List", icon: "view_list" }]; onSelected: key => Settings.network.wifiDetailsViewMode = key }
      }
      SettingsCard {
        title: "Bluetooth"
        description: "Device filtering and signal-strength polling."
        icon: "bluetooth"
        IToggle { label: "Hide unnamed devices"; checked: Settings.network.bluetoothHideUnnamedDevices; onToggled: checked => Settings.network.bluetoothHideUnnamedDevices = checked }
        IToggle { label: "Poll signal strength"; checked: Settings.network.bluetoothRssiPollingEnabled; onToggled: checked => Settings.network.bluetoothRssiPollingEnabled = checked }
        SettingsSpinRow { label: "Signal polling interval"; value: Settings.network.bluetoothRssiPollIntervalMs; from: 1000; to: 60000; stepSize: 1000; suffix: " ms"; enabled: Settings.network.bluetoothRssiPollingEnabled; onChanged: value => Settings.network.bluetoothRssiPollIntervalMs = value }
      }
    }
  }
}
