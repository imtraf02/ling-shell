pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.common
import qs.services
import qs.widgets
import qs.modules.panels as Panels
import qs.modules.notifications as Notifications

Item {
  id: root

  required property Item bar
  required property ShellScreen screen
  required property Item panels

  anchors.fill: parent
  anchors.margins: Settings.appearance.thickness
  anchors.topMargin: bar.implicitHeight
  readonly property var primaryPanel: {
    const panel = PanelService.backgroundSlotAssignments[0];
    return (panel && panel.screen === root.screen) ? panel : null;
  }
  readonly property var secondaryPanel: {
    const panel = PanelService.backgroundSlotAssignments[1];
    return (panel && panel.screen === root.screen) ? panel : null;
  }

  component PanelShadow: Item {
    id: shadowRoot

    required property var assignedPanel

    readonly property var panelRegion: assignedPanel?.panelRegion ?? null
    readonly property var panelItem: panelRegion?.panelItem ?? null
    readonly property real panelX: panelItem?.x ?? 0
    readonly property real panelY: panelItem?.y ?? 0
    readonly property real panelWidth: panelItem?.width ?? 0
    readonly property real panelHeight: panelItem?.height ?? 0
    readonly property real shadowMargin: 30
    // Keep the shadow a couple of pixels away from a joined edge. This also
    // prevents the antialiased Shape boundary from picking up a dark hairline.
    readonly property real joinInset: 2

    anchors.fill: parent
    visible: assignedPanel?.isPanelVisible === true && panelWidth > 0 && panelHeight > 0

    Item {
      id: shadowViewport

      readonly property real leftEdge: shadowRoot.panelItem?.atLeft === true
        ? shadowRoot.panelX + shadowRoot.joinInset
        : shadowRoot.panelX - shadowRoot.shadowMargin
      readonly property real topEdge: shadowRoot.panelItem?.atTop === true
        ? shadowRoot.panelY + shadowRoot.joinInset
        : shadowRoot.panelY - shadowRoot.shadowMargin
      readonly property real rightEdge: shadowRoot.panelItem?.atRight === true
        ? shadowRoot.panelX + shadowRoot.panelWidth - shadowRoot.joinInset
        : shadowRoot.panelX + shadowRoot.panelWidth + shadowRoot.shadowMargin
      readonly property real bottomEdge: shadowRoot.panelItem?.atBottom === true
        ? shadowRoot.panelY + shadowRoot.panelHeight - shadowRoot.joinInset
        : shadowRoot.panelY + shadowRoot.panelHeight + shadowRoot.shadowMargin

      x: Math.max(0, leftEdge)
      y: Math.max(0, topEdge)
      width: Math.max(0, Math.min(shadowRoot.width, rightEdge) - x)
      height: Math.max(0, Math.min(shadowRoot.height, bottomEdge) - y)
      clip: true

      Item {
        x: shadowRoot.panelX - shadowViewport.x
        y: shadowRoot.panelY - shadowViewport.y
        width: shadowRoot.panelWidth
        height: shadowRoot.panelHeight

        // A broad ambient shadow establishes separation without muddying the
        // surface. The tighter lower shadow gives the panel a physical lift.
        IElevation {
          anchors.fill: parent
          radius: Style.rounding.small
          level: 5
          color: Qt.alpha(ThemeService.palette.mShadow, 0.24)
          blur: 19
          spread: -2
          offset.y: 5
        }

        IElevation {
          anchors.fill: parent
          radius: Style.rounding.small
          level: 2
          color: Qt.alpha(ThemeService.palette.mShadow, 0.20)
          blur: 7
          spread: -1
          offset.y: 2
        }
      }
    }
  }

  PanelShadow {
    assignedPanel: root.secondaryPanel
  }

  PanelShadow {
    assignedPanel: root.primaryPanel
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    Panels.Background {
      assignedPanel: root.primaryPanel
    }

    Panels.Background {
      assignedPanel: root.secondaryPanel
    }

    Notifications.Background {
      assignedPanel: {
        const panel = root.panels.notificationsPopout;
        return (panel && panel.screen === root.screen) ? panel : null;
      }
    }
  }
}
