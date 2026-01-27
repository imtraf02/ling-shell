import Quickshell
import QtQuick
import qs.common
import qs.services

MouseArea {
  id: root

  required property ShellScreen screen
  required property Item bar
  required property bool isPanelOpen

  anchors.fill: parent
  hoverEnabled: true

  property point dragStart

  onPressed: event => dragStart = Qt.point(event.x, event.y)
  onContainsMouseChanged: {
    if (!containsMouse) {
      BarService.isHovered = false;
    }
  }

  onPositionChanged: event => {
    const x = event.x;
    const y = event.y;

    const dragX = x - dragStart.x;
    const dragY = y - dragStart.y;

    if (!BarService.isVisible && Settings.bar.showOnHover && y < bar.implicitHeight) {
      BarService.isHovered = true;
    }

    if (pressed && dragStart.y < bar.implicitHeight) {
      if (dragY > 20)
        BarService.isVisible = true;
      else if (dragY < 20) {
        BarService.isVisible = false;
      }
    }

    if (pressed && (dragStart.y > root.height - Settings.appearance.thickness - Style.rounding.small)) {
      if (dragY < -50)
        PanelService.getPanel("panel:launcher", screen).open();
      else if (dragY > 50) {
        PanelService.getPanel("panel:launcher", screen).close();
      }
    }
  }

  onClicked: event => {
    if (root.isPanelOpen) {
      // Fix the error when pressing open. (pressed)
      const panel = PanelService.openedPanel;
      const clickInPanelParent = mapToItem(panel.parent, event.x, event.y);
      const inPanel = clickInPanelParent.x >= panel.panelRegion.x && clickInPanelParent.x <= panel.panelRegion.x + panel.panelRegion.width && clickInPanelParent.y >= panel.panelRegion.y && clickInPanelParent.y <= panel.panelRegion.y + panel.panelRegion.height;
      if (!inPanel) {
        PanelService.openedPanel.close();
      }
    }
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.isPanelOpen && (PanelService.openedPanel.onEscapePressed !== undefined)
    onActivated: PanelService.openedPanel.onEscapePressed()
  }
}
