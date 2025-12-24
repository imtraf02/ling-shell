import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
  id: root

  property string label: ""
  property string description: ""
  property bool enabled: true
  property bool checked: false
  property bool hovering: false

  signal toggled(bool checked)

  Layout.fillWidth: true
  opacity: enabled ? 1.0 : 0.6
  spacing: Config.appearance.spacing.small

  ILabel {
    label: root.label
    description: root.description
  }

  ISwitch {
    Layout.alignment: Qt.AlignVCenter
    enabled: root.enabled
    checked: root.checked

    onToggled: {
      root.toggled(!root.checked);
    }
  }
}
