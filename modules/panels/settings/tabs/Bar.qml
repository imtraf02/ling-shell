pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets

ColumnLayout {
  spacing: Style.spacing.normal
  SettingsPage {
    title: "Bar"
    description: "Visibility, workspace presentation, and system tray behavior."
    icon: "crop_16_9"
    sectionId: "bar"

    SettingsCardGrid {
      id: grid
      SettingsCard {
        title: "Bar preview"
        description: "A compact representation of the configured top bar."
        icon: "preview"
        Layout.columnSpan: grid.columns
        IBox {
          Layout.fillWidth: true
          implicitHeight: 58
          color: ThemeService.palette.mSurfaceVariant
          RowLayout {
            anchors.fill: parent; anchors.margins: Style.padding.small; spacing: Style.spacing.small
            IIcon { icon: "home"; color: ThemeService.palette.mPrimary }
            Rectangle { implicitWidth: 72; implicitHeight: 28; radius: Style.rounding.full; color: ThemeService.palette.mPrimaryContainer; IText { anchors.centerIn: parent; text: "1  2  3"; color: ThemeService.palette.mOnPrimaryContainer; font.pointSize: Style.font.size.small } }
            Item { Layout.fillWidth: true }
            IText { text: "12:45"; font.weight: Font.Medium }
            Item { Layout.fillWidth: true }
            IIcon { icon: "network_wifi"; color: ThemeService.palette.mOnSurfaceVariant }
            IIcon { icon: "volume_up"; color: ThemeService.palette.mOnSurfaceVariant }
          }
        }
      }
      SettingsCard {
        title: "Visibility"
        description: "Where and when the bar appears."
        icon: "visibility"
        IToggle { label: "Persistent"; checked: Settings.bar.persistent; onToggled: checked => Settings.bar.persistent = checked }
        IToggle { label: "Show on hover"; enabled: !Settings.bar.persistent; checked: Settings.bar.showOnHover; onToggled: checked => Settings.bar.showOnHover = checked }
        SettingsSpinRow { label: "Pill hover delay"; value: Settings.delay.pill; from: 0; to: 2000; stepSize: 25; suffix: " ms"; onChanged: value => Settings.delay.pill = value }
      }
      SettingsCard {
        title: "Monitors"
        description: "No selection means show the bar on every monitor."
        icon: "desktop_windows"
        Repeater {
          model: Quickshell.screens
          delegate: IToggle {
            required property ShellScreen modelData
            label: modelData.name
            checked: Settings.bar.monitors.includes(modelData.name)
            onToggled: checked => {
              const monitors = Settings.bar.monitors || [];
              Settings.bar.monitors = checked ? monitors.concat([modelData.name]) : monitors.filter(name => name !== modelData.name);
            }
          }
        }
      }
      SettingsCard {
        title: "Workspaces"
        description: "Niri workspace presence and indicators."
        icon: "grid_view"
        Layout.columnSpan: grid.columns
        SettingsSpinRow { label: "Visible workspaces"; value: Settings.bar.workspace.shown; from: 1; to: 20; onChanged: value => Settings.bar.workspace.shown = value }
        IToggle { label: "Active indicator"; checked: Settings.bar.workspace.activeIndicator; onToggled: checked => Settings.bar.workspace.activeIndicator = checked }
        IToggle { label: "Active indicator trail"; checked: Settings.bar.workspace.activeTrail; onToggled: checked => Settings.bar.workspace.activeTrail = checked }
        IToggle { label: "Occupied background"; checked: Settings.bar.workspace.occupiedBg; onToggled: checked => Settings.bar.workspace.occupiedBg = checked }
        IToggle { label: "Show window icons"; checked: Settings.bar.workspace.showWindows; onToggled: checked => Settings.bar.workspace.showWindows = checked }
        IToggle { label: "Show windows on special workspaces"; checked: Settings.bar.workspace.showWindowsOnSpecialWorkspaces; onToggled: checked => Settings.bar.workspace.showWindowsOnSpecialWorkspaces = checked }
        IToggle { label: "Per-monitor workspaces"; checked: Settings.bar.workspace.perMonitorWorkspaces; onToggled: checked => Settings.bar.workspace.perMonitorWorkspaces = checked }
        SettingsChoiceGroup { label: "Label capitalization"; currentKey: Settings.bar.workspace.capitalisation; model: [{ key: "preserve", name: "Preserve" }, { key: "lower", name: "Lowercase" }, { key: "upper", name: "Uppercase" }]; onSelected: key => Settings.bar.workspace.capitalisation = key }
        ITextInput { label: "Default label"; text: Settings.bar.workspace.label; onEditingFinished: Settings.bar.workspace.label = text }
        ITextInput { label: "Occupied label"; text: Settings.bar.workspace.occupiedLabel; onEditingFinished: Settings.bar.workspace.occupiedLabel = text }
        ITextInput { label: "Active label"; text: Settings.bar.workspace.activeLabel; onEditingFinished: Settings.bar.workspace.activeLabel = text }
      }
      SettingsCard {
        title: "System tray"
        description: "Filter and highlight tray entries."
        icon: "widgets"
        Layout.columnSpan: grid.columns
        IToggle { label: "Colorize tray icons"; checked: Settings.bar.tray.colorize; onToggled: checked => Settings.bar.tray.colorize = checked }
        SettingsListEditor { label: "Blacklist"; placeholder: "org.example.*"; values: Settings.bar.tray.blacklist; onUpdated: values => Settings.bar.tray.blacklist = values }
        SettingsListEditor { label: "Favorites"; placeholder: "Application name"; values: Settings.bar.tray.favorites; onUpdated: values => Settings.bar.tray.favorites = values }
      }
    }
  }
}
