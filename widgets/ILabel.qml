import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

ColumnLayout {
  id: root

  property string label: ""
  property string description: ""
  property color labelColor: ThemeService.palette.mOnSurface
  property color descriptionColor: ThemeService.palette.mOutline
  property int labelSize: Style.font.size.larger
  property int descriptionSize: Style.font.size.small

  spacing: Style.spacing.small
  Layout.fillWidth: true

  IText {
    text: root.label
    font.pointSize: root.labelSize
    color: root.labelColor
    visible: root.label !== ""
    Layout.fillWidth: true
  }

  IText {
    text: root.description
    font.pointSize: root.descriptionSize
    color: root.descriptionColor
    wrapMode: Text.WordWrap
    visible: root.description !== ""
    Layout.fillWidth: true
  }
}
