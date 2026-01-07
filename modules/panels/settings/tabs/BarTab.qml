import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.widgets

ColumnLayout {
  id: root

  readonly property int padding: Style.appearance.padding.normal
  spacing: Style.appearance.spacing.larger

  IToggle {
    label: "Persistent"
    description: "Keep the bar visible."
    checked: Settings.bar.persistent
    onToggled: checked => Settings.bar.persistent = checked
  }

  IToggle {
    label: "Show on hover"
    description: "Show the bar when hovering over the screen."
    enabled: !Settings.bar.persistent
    checked: Settings.bar.showOnHover
    onToggled: checked => Settings.bar.showOnHover = checked
  }

  IDivider {
    Layout.fillWidth: true
    Layout.topMargin: root.padding
    Layout.bottomMargin: root.padding
  }
}
