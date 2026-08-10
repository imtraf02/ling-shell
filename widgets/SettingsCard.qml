import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

IBox {
  id: root

  property string title: ""
  property string description: ""
  property string icon: "tune"
  property bool advanced: false
  property bool expanded: !advanced
  property string badge: ""

  default property alias content: cardContent.data

  Layout.fillWidth: true
  implicitHeight: cardLayout.implicitHeight + Style.padding.normal * 2
  color: ThemeService.palette.mSurfaceContainer

  Behavior on implicitHeight { IAnim {} }

  ColumnLayout {
    id: cardLayout
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.padding.normal
    spacing: Style.spacing.small

    RowLayout {
      id: cardHeader
      Layout.fillWidth: true
      spacing: Style.spacing.small

      IIcon {
        icon: root.icon
        color: ThemeService.palette.mPrimary
        font.pointSize: Style.font.size.large
      }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        IText { text: root.title; font.weight: Font.Medium }
        IText {
          Layout.fillWidth: true
          visible: root.description !== ""
          text: root.description
          color: ThemeService.palette.mOnSurfaceVariant
          wrapMode: Text.WordWrap
          font.pointSize: Style.font.size.small
        }
      }
      Rectangle {
        visible: root.badge !== ""
        implicitWidth: badgeText.implicitWidth + Style.padding.small * 2
        implicitHeight: badgeText.implicitHeight + Style.padding.small
        radius: Style.rounding.full
        color: Qt.alpha(ThemeService.palette.mPrimary, 0.14)
        IText {
          id: badgeText
          anchors.centerIn: parent
          text: root.badge
          color: ThemeService.palette.mPrimary
          font.pointSize: Style.font.size.small
        }
      }
      IIconButton {
        visible: root.advanced
        icon: root.expanded ? "expand_less" : "expand_more"
        onClicked: root.expanded = !root.expanded
      }
    }

    ColumnLayout {
      id: cardContent
      Layout.fillWidth: true
      visible: root.expanded
      opacity: root.expanded ? 1.0 : 0.0
      spacing: Style.spacing.small
      Behavior on opacity { IAnim {} }
    }
  }
}
