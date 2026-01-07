import QtQuick
import Quickshell
import qs.commons
import qs.services
import qs.widgets

Rectangle {
  id: root

  property ShellScreen screen

  property bool hovered: false

  color: hovered ? ThemeService.palette.mSurfaceContainerHigh : ThemeService.palette.mSurfaceContainer
  radius: Settings.appearance.cornerRadius

  implicitWidth: clock.implicitWidth + Style.bar.innerHeight * 0.5
  implicitHeight: Style.bar.innerHeight

  Behavior on color {
    ICAnim {}
  }

  IText {
    id: clock
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    horizontalAlignment: Text.AlignHCenter
    text: TimeService.format("hh:mm A • ddd d")
    family: Settings.appearance.font.clock
    color: ThemeService.palette.mPrimary
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onEntered: {
      root.hovered = true;
    }
    onExited: {
      root.hovered = false;
    }
    onClicked: {
      VisibilityService.getPanel("calendar", root.screen)?.toggle(this);
    }
  }
}
