import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.services

ColumnLayout {
  id: root

  property string label: ""
  property string description: ""
  property color labelColor: ThemeService.palette.mOnSurface
  property color descriptionColor: ThemeService.palette.mOutline
  property int labelSize: Style.appearance.font.size.larger
  property int descriptionSize: Style.appearance.font.size.small

  spacing: Style.appearance.spacing.small
  Layout.fillWidth: true

  IText {
    text: root.label
    pointSize: root.labelSize
    color: root.labelColor
    visible: root.label !== ""
    Layout.fillWidth: true
  }

  IText {
    text: root.description
    pointSize: root.descriptionSize
    color: root.descriptionColor
    wrapMode: Text.WordWrap
    visible: root.description !== ""
    Layout.fillWidth: true
  }
}
