import QtQuick
import qs.commons
import qs.services

Rectangle {
  id: root

  property string icon
  property real size: Style.appearance.widget.size
  property real iconSize: Math.max(1, size * 0.48)

  property bool enabled: true
  property bool hovering: false

  property color colorBg: ThemeService.palette.mSurfaceVariant
  property color colorFg: ThemeService.palette.mPrimary
  property color colorBgHover: ThemeService.palette.mPrimary
  property color colorFgHover: ThemeService.palette.mOnPrimary
  property color colorBorder: Qt.alpha(ThemeService.palette.mOutline, 0.2)
  property color colorBorderHover: Qt.alpha(ThemeService.palette.mOutline, 0.2)

  implicitWidth: size
  implicitHeight: size
  color: root.enabled && root.hovering ? colorBgHover : colorBg
  radius: Settings.appearance.cornerRadius
  border.color: root.enabled && root.hovering ? colorBorderHover : colorBorder
  border.width: 1

  signal clicked
  signal rightClicked
  signal entered
  signal exited

  Behavior on color {
    ICAnim {}
  }

  IIcon {
    icon: root.icon
    pointSize: Math.max(1, root.width * 0.48)
    color: root.enabled && root.hovering ? root.colorFgHover : root.colorFg
    x: (root.width - width) / 2
    y: (root.height - height) / 2 + (height - contentHeight) / 2

    Behavior on color {
      ICAnim {}
    }
  }

  MouseArea {
    enabled: true
    anchors.fill: parent
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    onEntered: {
      root.hovering = root.enabled ? true : false;
      root.entered();
    }
    onExited: {
      root.hovering = false;
      root.exited();
    }
    onClicked: mouse => {
      if (mouse.button == Qt.LeftButton) {
        root.clicked();
      } else if (mouse.button == Qt.RightButton) {
        root.rightClicked();
      }
    }
  }
}
