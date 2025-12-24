import QtQuick
import QtQuick.Layouts
import qs.config
import qs.commons
import qs.services

Rectangle {
  id: root
  property string text: ""
  property bool checked: false
  property int tabIndex: 0

  property bool isHovered: false

  signal clicked

  Layout.fillWidth: true
  Layout.fillHeight: true

  radius: Settings.appearance.cornerRadius
  color: root.checked ? ThemeService.palette.mPrimary : (root.isHovered ? ThemeService.palette.mPrimary : ThemeService.palette.mSurface)

  Behavior on color {
    ICAnim {}
  }

  IText {
    id: tabText
    anchors.centerIn: parent
    text: root.text
    pointSize: Config.appearance.font.size.smaller
    color: root.checked ? ThemeService.palette.mOnPrimary : root.isHovered ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
      ICAnim {}
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: root.isHovered = true
    onExited: root.isHovered = false
    onClicked: {
      root.clicked();
      if (root.parent && root.parent.parent && root.parent.parent?.currentIndex !== undefined) {
        root.parent.parent.currentIndex = root.tabIndex;
      }
    }
  }
}
