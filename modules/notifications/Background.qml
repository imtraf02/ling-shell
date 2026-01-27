import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

ShapePath {
  id: root

  property var assignedPanel: null
  property color defaultBackgroundColor: ThemeService.palette.mSurface

  readonly property real radius: Style.rounding.small

  readonly property bool shouldFlatten: assignedPanel ? ShapeCornerHelper.shouldFlatten(panelWidth, panelHeight, radius) : false
  readonly property real effectiveRadius: shouldFlatten ? ShapeCornerHelper.getFlattenedRadius(Math.min(panelWidth, panelHeight), radius) : radius
  readonly property color effectiveBackgroundColor: {
    if (!assignedPanel || !assignedPanel.visible)
      return "transparent";
    if (assignedPanel.panelBackgroundColor !== undefined) {
      return assignedPanel.panelBackgroundColor;
    }
    return defaultBackgroundColor;
  }

  strokeWidth: -1

  readonly property real panelX: assignedPanel ? assignedPanel.x : 0
  readonly property real panelY: assignedPanel ? assignedPanel.y : 0
  readonly property real panelWidth: assignedPanel ? assignedPanel.width : 0
  readonly property real panelHeight: assignedPanel ? assignedPanel.height : 0

  startX: panelX + effectiveRadius
  startY: panelY
  fillColor: effectiveBackgroundColor

  PathLine {
    relativeX: root.panelWidth - root.effectiveRadius - root.effectiveRadius
    relativeY: 0
  }

  PathArc {
    relativeX: root.effectiveRadius
    relativeY: -root.effectiveRadius
    radiusX: root.effectiveRadius
    radiusY: root.effectiveRadius
    direction: PathArc.Counterclockwise
  }

  PathLine {
    relativeX: 0
    relativeY: root.panelHeight - (-root.effectiveRadius) - (-root.effectiveRadius)
  }

  PathArc {
    relativeX: -root.effectiveRadius
    relativeY: -root.effectiveRadius
    radiusX: root.effectiveRadius
    radiusY: root.effectiveRadius
    direction: PathArc.Counterclockwise
  }

  PathLine {
    relativeX: -(root.panelWidth - root.effectiveRadius - (-root.effectiveRadius))
    relativeY: 0
  }

  PathArc {
    relativeX: -(-root.effectiveRadius)
    relativeY: -root.effectiveRadius
    radiusX: root.effectiveRadius
    radiusY: root.effectiveRadius
    direction: PathArc.Counterclockwise
  }

  PathLine {
    relativeX: 0
    relativeY: -(root.panelHeight - root.effectiveRadius - root.effectiveRadius)
  }

  PathArc {
    relativeX: root.effectiveRadius
    relativeY: -root.effectiveRadius
    radiusX: root.effectiveRadius
    radiusY: root.effectiveRadius
    direction: PathArc.Clockwise
  }
}
