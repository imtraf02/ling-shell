import Quickshell
import QtQuick
import qs.commons
import qs.services
import qs.modules.bar

MouseArea {
  id: root

  required property ShellScreen screen
  required property Bar bar
  required property Panels panels

  anchors.fill: parent
  hoverEnabled: true

  property point dragStart

  onPressed: event => dragStart = Qt.point(event.x, event.y)
  onContainsMouseChanged: {
    if (!containsMouse) {
      VisibilityService.barIsHovered = false;
    }
  }

  onPositionChanged: event => {
    const x = event.x;
    const y = event.y;

    const dragX = x - dragStart.x;
    const dragY = y - dragStart.y;

    // Show bar in non-exclusive mode on hover
    if (!VisibilityService.bar && Settings.bar.showOnHover && y < bar.implicitHeight) {
      VisibilityService.barIsHovered = true;
    }

    if (pressed && dragStart.y < bar.implicitHeight) {
      if (dragY > 20)
        VisibilityService.bar = true;
      else if (dragY < 20) {
        VisibilityService.bar = false;
      }
    }

    if (pressed && (dragStart.y > root.height - Settings.appearance.thickness - panels.launcher.height - Settings.appearance.cornerRadius)) {
      if (dragY < -50)
        VisibilityService.getPanel("launcher", screen).open();
      else if (dragY > 50) {
        VisibilityService.getPanel("launcher", screen).close();
      }
    }
  }

  onClicked: event => {
    if (VisibilityService.openedPanel !== null) {
      const panel = VisibilityService.openedPanel;

      const clickInPanelParent = mapToItem(panel.parent, event.x, event.y);

      const inPanel = clickInPanelParent.x >= panel.x && clickInPanelParent.x <= panel.x + panel.width && clickInPanelParent.y >= panel.y && clickInPanelParent.y <= panel.y + panel.height;

      if (!inPanel) {
        VisibilityService.openedPanel.close();
      }
    }
  }
}
