pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.commons

Shape {
  id: root
  required property Item bar
  required property Panels panels

  anchors.fill: parent
  anchors.margins: Settings.appearance.thickness
  anchors.topMargin: bar.implicitHeight
  preferredRendererType: Shape.CurveRenderer

  BarPanelBackground {
    panel: root.panels.calendar
  }
  BarPanelBackground {
    panel: root.panels.battery
  }
  BarPanelBackground {
    panel: root.panels.audio
  }
  BarPanelBackground {
    panel: root.panels.wifi
  }
  BarPanelBackground {
    panel: root.panels.brightness
  }
  BarPanelBackground {
    panel: root.panels.trayDrawer
  }
  BarPanelBackground {
    panel: root.panels.trayMenu
  }
  BarPanelBackground {
    panel: root.panels.controlCenter
  }
  BarPanelBackground {
    panel: root.panels.bluetooth
  }
  BarPanelBackground {
    panel: root.panels.media
  }
  BarPanelBackground {
    panel: root.panels.notificationsPanel
  }

  PanelBackground {
    panel: root.panels.launcher
    topLeftCornerState: 0
    topRightCornerState: 0
    bottomLeftCornerState: 1
    bottomRightCornerState: 1
  }

  PanelBackground {
    panel: root.panels.session
    topLeftCornerState: 0
    topRightCornerState: 2
    bottomLeftCornerState: 0
    bottomRightCornerState: 2
  }

  PanelBackground {
    panel: root.panels.notificationsPopout
    topLeftCornerState: 0
    topRightCornerState: 2
    bottomLeftCornerState: 1
    bottomRightCornerState: 1
  }

  component BarPanelBackground: PanelBackground {
    topLeftCornerState: panel.y <= 0 ? 1 : 0
    topRightCornerState: panel.y <= 0 ? 1 : 0
    bottomLeftCornerState: panel.x <= 1 ? 2 : 0
    bottomRightCornerState: panel.x + panel.width + 1 >= root.width ? 2 : 0
  }
}
