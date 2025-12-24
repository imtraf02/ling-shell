import QtQuick
import Quickshell
import qs.config
import qs.commons
import qs.services
import qs.widgets

Rectangle {
  id: root

  property ShellScreen screen

  property bool hovered: false

  readonly property int size: Config.bar.sizes.innerHeight
  readonly property int iconSize: Math.max(1, Math.round(size * 0.66))

  implicitWidth: size
  implicitHeight: size

  color: hovered ? ThemeService.palette.mSurfaceContainerHigh : ThemeService.palette.mSurfaceContainer
  radius: Settings.appearance.cornerRadius

  Behavior on color {
    ICAnim {}
  }

  IColouredIcon {
    id: iconImage
    source: DistroService.osLogo
    implicitSize: root.iconSize
    anchors.centerIn: parent
    asynchronous: true
    colour: ThemeService.palette.mPrimary
  }

  MouseArea {
    enabled: true
    anchors.fill: parent
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    onEntered: {
      root.hovered = true;
    }
    onExited: {
      root.hovered = false;
    }
    onClicked: {
      VisibilityService.getPanel("control-center", root.screen)?.toggle(this);
    }
  }
}
