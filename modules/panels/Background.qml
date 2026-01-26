import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

ShapePath {
  id: root

  property var assignedPanel: null

  property color defaultBackgroundColor: ThemeService.palette.mSurface

  readonly property real radius: Settings.appearance.cornerRadius

  readonly property var panelRegion: assignedPanel?.panelRegion ?? null

  readonly property var panelBg: (panelRegion && panelRegion.visible) ? panelRegion.panelItem : null

  readonly property color effectiveBackgroundColor: {
    if (!assignedPanel)
      return "transparent";
    if (assignedPanel.panelBackgroundColor !== undefined) {
      return assignedPanel.panelBackgroundColor;
    }
    return defaultBackgroundColor;
  }

  readonly property real panelX: panelBg ? panelBg.x : 0
  readonly property real panelY: panelBg ? panelBg.y : 0
  readonly property real panelWidth: panelBg ? panelBg.width : 0
  readonly property real panelHeight: panelBg ? panelBg.height : 0

  readonly property bool shouldFlatten: panelBg ? ShapeCornerHelper.shouldFlatten(panelWidth, panelHeight, radius) : false

  readonly property real effectiveRadius: shouldFlatten ? ShapeCornerHelper.getFlattenedRadius(Math.min(panelWidth, panelHeight), radius) : radius

  function getCornerRadius(cornerState) {
    if (cornerState === -1)
      return 0;
    return effectiveRadius;
  }

  readonly property real tlMultX: panelBg ? ShapeCornerHelper.getMultX(panelBg.topLeftCornerState) : 1
  readonly property real tlMultY: panelBg ? ShapeCornerHelper.getMultY(panelBg.topLeftCornerState) : 1
  readonly property real tlRadius: panelBg ? getCornerRadius(panelBg.topLeftCornerState) : 0

  readonly property real trMultX: panelBg ? ShapeCornerHelper.getMultX(panelBg.topRightCornerState) : 1
  readonly property real trMultY: panelBg ? ShapeCornerHelper.getMultY(panelBg.topRightCornerState) : 1
  readonly property real trRadius: panelBg ? getCornerRadius(panelBg.topRightCornerState) : 0

  readonly property real brMultX: panelBg ? ShapeCornerHelper.getMultX(panelBg.bottomRightCornerState) : 1
  readonly property real brMultY: panelBg ? ShapeCornerHelper.getMultY(panelBg.bottomRightCornerState) : 1
  readonly property real brRadius: panelBg ? getCornerRadius(panelBg.bottomRightCornerState) : 0

  readonly property real blMultX: panelBg ? ShapeCornerHelper.getMultX(panelBg.bottomLeftCornerState) : 1
  readonly property real blMultY: panelBg ? ShapeCornerHelper.getMultY(panelBg.bottomLeftCornerState) : 1
  readonly property real blRadius: panelBg ? getCornerRadius(panelBg.bottomLeftCornerState) : 0

  strokeWidth: -1

  startX: panelX + tlRadius * tlMultX
  startY: panelY

  fillColor: effectiveBackgroundColor

  PathLine {
    relativeX: root.panelWidth - root.tlRadius * root.tlMultX - root.trRadius * root.trMultX
    relativeY: 0
  }

  PathArc {
    relativeX: root.trRadius * root.trMultX
    relativeY: root.trRadius * root.trMultY
    radiusX: root.trRadius
    radiusY: root.trRadius
    direction: ShapeCornerHelper.getArcDirection(root.trMultX, root.trMultY)
  }

  PathLine {
    relativeX: 0
    relativeY: root.panelHeight - root.trRadius * root.trMultY - root.brRadius * root.brMultY
  }

  PathArc {
    relativeX: -root.brRadius * root.brMultX
    relativeY: root.brRadius * root.brMultY
    radiusX: root.brRadius
    radiusY: root.brRadius
    direction: ShapeCornerHelper.getArcDirection(root.brMultX, root.brMultY)
  }

  PathLine {
    relativeX: -(root.panelWidth - root.brRadius * root.brMultX - root.blRadius * root.blMultX)
    relativeY: 0
  }

  PathArc {
    relativeX: -root.blRadius * root.blMultX
    relativeY: -root.blRadius * root.blMultY
    radiusX: root.blRadius
    radiusY: root.blRadius
    direction: ShapeCornerHelper.getArcDirection(root.blMultX, root.blMultY)
  }

  PathLine {
    relativeX: 0
    relativeY: -(root.panelHeight - root.blRadius * root.blMultY - root.tlRadius * root.tlMultY)
  }

  PathArc {
    relativeX: root.tlRadius * root.tlMultX
    relativeY: -root.tlRadius * root.tlMultY
    radiusX: root.tlRadius
    radiusY: root.tlRadius
    direction: ShapeCornerHelper.getArcDirection(root.tlMultX, root.tlMultY)
  }
}
