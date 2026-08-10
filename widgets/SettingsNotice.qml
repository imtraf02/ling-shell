import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Rectangle {
  id: root

  property string icon: "info"
  property string text: ""
  property bool warning: false

  Layout.fillWidth: true
  implicitHeight: noticeRow.implicitHeight + Style.padding.normal * 2
  radius: Style.rounding.small
  color: Qt.alpha(warning ? ThemeService.palette.mTertiary : ThemeService.palette.mPrimary, 0.13)
  border.width: 1
  border.color: Qt.alpha(warning ? ThemeService.palette.mTertiary : ThemeService.palette.mPrimary, 0.35)

  RowLayout {
    id: noticeRow
    anchors.fill: parent
    anchors.margins: Style.padding.normal
    spacing: Style.spacing.small

    IIcon {
      icon: root.icon
      color: root.warning ? ThemeService.palette.mTertiary : ThemeService.palette.mPrimary
    }
    IText {
      Layout.fillWidth: true
      text: root.text
      wrapMode: Text.WordWrap
      color: ThemeService.palette.mOnSurface
      font.pointSize: Style.font.size.small
    }
  }
}
