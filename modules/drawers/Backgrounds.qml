pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.common
import qs.services
import qs.modules.panels as Panels
import qs.modules.notifications as Notifications

Shape {
  id: root

  required property Item bar
  required property ShellScreen screen
  required property Item panels

  anchors.fill: parent
  anchors.margins: Settings.appearance.thickness
  anchors.topMargin: bar.implicitHeight
  preferredRendererType: Shape.CurveRenderer

  Panels.Background {
    assignedPanel: {
      const p = PanelService.backgroundSlotAssignments[0];
      return (p && p.screen === root.screen) ? p : null;
    }
  }

  Panels.Background {
    assignedPanel: {
      const p = PanelService.backgroundSlotAssignments[1];
      return (p && p.screen === root.screen) ? p : null;
    }
  }

  Panels.Background {
    assignedPanel: {
      const p = PanelService.backgroundSlotAssignments[1];
      return (p && p.screen === root.screen) ? p : null;
    }
  }

  Panels.Background {
    assignedPanel: {
      const p = PanelService.backgroundSlotAssignments[1];
      return (p && p.screen === root.screen) ? p : null;
    }
  }

  Notifications.Background {
    assignedPanel: {
      const p = root.panels.notificationsPopout;
      return (p && p.screen === root.screen) ? p : null;
    }
  }
}
