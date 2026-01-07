import QtQuick
import QtQuick.Controls
import qs.commons
import qs.services

RadioButton {
  id: root

  property int pointSize: Style.appearance.font.size.small

  indicator: Rectangle {
    id: outerCircle

    implicitWidth: Style.appearance.widget.size * 0.625 * root.pointSize / Style.appearance.font.size.small
    implicitHeight: Style.appearance.widget.size * 0.625 * root.pointSize / Style.appearance.font.size.small
    radius: width * 0.5
    color: "transparent"
    border.color: root.checked ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurface
    border.width: 1
    anchors.verticalCenter: parent.verticalCenter

    // Inner filled circle when checked
    Rectangle {
      anchors.fill: parent
      anchors.margins: parent.width * 0.3
      radius: width * 0.5
      color: Qt.alpha(ThemeService.palette.mPrimary, root.checked ? 1 : 0)

      Behavior on color {
        ICAnim {}
      }
    }

    Behavior on border.color {
      ICAnim {}
    }
  }

  contentItem: IText {
    text: root.text
    pointSize: root.pointSize
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: outerCircle.right
    anchors.right: parent.right
    anchors.leftMargin: Style.appearance.spacing.small
  }
}
