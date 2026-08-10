import QtQuick
import Quickshell
import qs.common
import qs.services
import qs.widgets

Rectangle {
  id: root

  property ShellScreen screen

  property bool hovered: false

  readonly property int size: Style.bar.innerHeight
  readonly property int iconSize: Math.max(1, Math.round(size * 0.66))

  implicitWidth: size
  implicitHeight: size

  color: hovered ? ThemeService.palette.mSurfaceContainerHigh : ThemeService.palette.mSurfaceContainer
  radius: Style.rounding.small

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
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton || !Settings.dashboard.enabled) {
        PanelService.getPanel("panel:control-center", root.screen).toggle(root);
        return;
      }
      if (mouse.button === Qt.LeftButton) {
        DashboardService.resetToDefault();
        const panel = PanelService.getPanel("panel:dashboard", root.screen);
        if (panel)
          panel.toggle();
        else
          Qt.callLater(() => PanelService.getPanel("panel:dashboard", root.screen)?.toggle());
      }
    }
  }
}
