import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

Rectangle {
  id: root

  property string title: ""
  property string icon: ""
  property color cardColor: ThemeService.palette.mSurfaceContainer
  default property alias contentData: body.data

  color: cardColor
  radius: Style.rounding.normal
  clip: true

  RowLayout {
    id: header
    visible: root.title !== ""
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.padding.normal
    spacing: Style.spacing.small

    IIcon {
      visible: root.icon !== ""
      icon: root.icon
      color: ThemeService.palette.mPrimary
      font.pointSize: Style.font.size.large
    }
    IText {
      Layout.fillWidth: true
      text: root.title
      font.weight: Font.DemiBold
      font.pointSize: Style.font.size.normal
    }
  }

  Item {
    id: body
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.top: header.visible ? header.bottom : parent.top
    anchors.margins: Style.padding.normal
    anchors.topMargin: header.visible ? Style.spacing.small : Style.padding.normal
  }
}
