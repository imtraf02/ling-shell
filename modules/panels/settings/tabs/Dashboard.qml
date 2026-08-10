import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

ColumnLayout {
  spacing: Style.spacing.normal

  SettingsPage {
    title: "Dashboard"
    description: "Choose dashboard pages, weather, and resource cards. Left-click the OS icon to open it; right-click opens Control Center."
    icon: "dashboard"
    sectionId: "dashboard"

    SettingsCardGrid {
      id: grid

      SettingsCard {
        title: "Availability"
        description: "Control the dashboard and its top navigation. Home remains as a safe fallback if every page is hidden."
        icon: "view_quilt"
        IToggle { label: "Enable dashboard"; checked: Settings.dashboard.enabled; onToggled: checked => Settings.dashboard.enabled = checked }
        SettingsChoiceGroup {
          label: "Default page"
          currentKey: Settings.dashboard.defaultTab
          model: [
            { key: "home", name: "Home", icon: "home" },
            { key: "media", name: "Media", icon: "music_note" },
            { key: "performance", name: "Performance", icon: "monitoring" },
            { key: "weather", name: "Weather", icon: "partly_cloudy_day" }
          ]
          onSelected: key => Settings.dashboard.defaultTab = key
        }
        IToggle { label: "Show Home"; checked: Settings.dashboard.showHome; onToggled: checked => Settings.dashboard.showHome = checked }
        IToggle { label: "Show Media"; checked: Settings.dashboard.showMedia; onToggled: checked => Settings.dashboard.showMedia = checked }
        IToggle { label: "Show Performance"; checked: Settings.dashboard.showPerformance; onToggled: checked => Settings.dashboard.showPerformance = checked }
        IToggle { label: "Show Weather"; checked: Settings.dashboard.showWeather; onToggled: checked => Settings.dashboard.showWeather = checked }
      }

      SettingsCard {
        title: "Weather"
        description: "Forecasts use Open-Meteo and refresh only while a weather consumer is visible."
        icon: "partly_cloudy_day"
        ITextInput { label: "Location"; text: Settings.dashboard.weatherLocation; placeholderText: "Ho Chi Minh City"; onEditingFinished: Settings.dashboard.weatherLocation = text.trim() || "Ho Chi Minh City" }
        SettingsSpinRow { label: "Refresh interval"; value: Settings.dashboard.weatherRefreshInterval / 60000; from: 5; to: 180; stepSize: 5; suffix: " min"; onChanged: value => Settings.dashboard.weatherRefreshInterval = value * 60000 }
        SettingsNotice { icon: "privacy_tip"; text: "Only the configured city name is sent. IP geolocation is not used." }
      }

      SettingsCard {
        Layout.columnSpan: grid.columns
        title: "Performance cards"
        description: "Hidden cards do not change the polling service; the service itself stops when Home and Performance are not visible."
        icon: "monitoring"
        GridLayout {
          Layout.fillWidth: true
          columns: width >= 720 ? 3 : 1
          columnSpacing: Style.spacing.normal
          rowSpacing: Style.spacing.small
          IToggle { label: "CPU"; checked: Settings.dashboard.performance.showCpu; onToggled: checked => Settings.dashboard.performance.showCpu = checked }
          IToggle { label: "GPU"; checked: Settings.dashboard.performance.showGpu; onToggled: checked => Settings.dashboard.performance.showGpu = checked }
          IToggle { label: "Memory"; checked: Settings.dashboard.performance.showMemory; onToggled: checked => Settings.dashboard.performance.showMemory = checked }
          IToggle { label: "Swap"; checked: Settings.dashboard.performance.showSwap; onToggled: checked => Settings.dashboard.performance.showSwap = checked }
          IToggle { label: "Storage"; checked: Settings.dashboard.performance.showStorage; onToggled: checked => Settings.dashboard.performance.showStorage = checked }
          IToggle { label: "Network"; checked: Settings.dashboard.performance.showNetwork; onToggled: checked => Settings.dashboard.performance.showNetwork = checked }
          IToggle { label: "Battery"; checked: Settings.dashboard.performance.showBattery; onToggled: checked => Settings.dashboard.performance.showBattery = checked }
        }
      }

      SettingsCard {
        Layout.columnSpan: grid.columns
        title: "Command line"
        description: "Control the dashboard without keeping another process alive."
        icon: "terminal"
        SettingsNotice { icon: "code"; text: "qs ipc call dashboard toggle · qs ipc call dashboard open performance · qs ipc call dashboard close" }
      }
    }
  }
}
