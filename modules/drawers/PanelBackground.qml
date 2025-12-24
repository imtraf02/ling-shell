import QtQuick
import QtQuick.Shapes
import qs.commons
import qs.services
import qs.widgets

ShapePath {
  id: root

  required property Item panel

  // Corner states: -1 = flat, 0 = normal, 1 = horizontal invert, 2 = vertical invert
  property int topLeftCornerState: 0
  property int topRightCornerState: 0
  property int bottomLeftCornerState: 0
  property int bottomRightCornerState: 0

  readonly property real radius: Settings.appearance.cornerRadius

  // Cached panel properties for safe access
  readonly property real panelX: panel ? panel.x : 0
  readonly property real panelY: panel ? panel.y : 0
  readonly property real panelWidth: panel ? panel.width : 0
  readonly property real panelHeight: panel ? panel.height : 0

  // Flattening logic for small panels
  readonly property bool shouldFlatten: panel ? getShouldFlatten(panelWidth, panelHeight, radius) : false
  readonly property real effectiveRadius: shouldFlatten ? getFlattenedRadius(Math.min(panelWidth, panelHeight), radius) : radius

  // Helper function to get corner radius based on state
  function getCornerRadius(cornerState) {
    if (cornerState === -1)
      return 0;
    return effectiveRadius;
  }

  // Per-corner multipliers and radii
  readonly property real tlMultX: panel ? getMultX(topLeftCornerState) : 1
  readonly property real tlMultY: panel ? getMultY(topLeftCornerState) : 1
  readonly property real tlRadius: panel ? getCornerRadius(topLeftCornerState) : 0

  readonly property real trMultX: panel ? getMultX(topRightCornerState) : 1
  readonly property real trMultY: panel ? getMultY(topRightCornerState) : 1
  readonly property real trRadius: panel ? getCornerRadius(topRightCornerState) : 0

  readonly property real brMultX: panel ? getMultX(bottomRightCornerState) : 1
  readonly property real brMultY: panel ? getMultY(bottomRightCornerState) : 1
  readonly property real brRadius: panel ? getCornerRadius(bottomRightCornerState) : 0

  readonly property real blMultX: panel ? getMultX(bottomLeftCornerState) : 1
  readonly property real blMultY: panel ? getMultY(bottomLeftCornerState) : 1
  readonly property real blRadius: panel ? getCornerRadius(bottomLeftCornerState) : 0

  // Helper functions
  function getMultX(cornerState) {
    return cornerState === 1 ? -1 : 1;
  }

  function getMultY(cornerState) {
    return cornerState === 2 ? -1 : 1;
  }

  function getArcDirection(multX, multY) {
    return ((multX < 0) !== (multY < 0)) ? PathArc.Counterclockwise : PathArc.Clockwise;
  }

  function getFlattenedRadius(dimension, requestedRadius) {
    if (dimension < requestedRadius * 2) {
      return dimension / 2;
    }
    return requestedRadius;
  }

  function getShouldFlatten(width, height, radius) {
    return width < radius * 2 || height < radius * 2;
  }

  strokeWidth: -1
  startX: panelX + tlRadius * tlMultX
  startY: panelY
  fillColor: ThemeService.palette.mSurface

  // Top edge (moving right)
  PathLine {
    relativeX: root.panelWidth - root.tlRadius * root.tlMultX - root.trRadius * root.trMultX
    relativeY: 0
  }

  // Top-right corner arc
  PathArc {
    relativeX: root.trRadius * root.trMultX
    relativeY: root.trRadius * root.trMultY
    radiusX: root.trRadius
    radiusY: root.trRadius
    direction: root.getArcDirection(root.trMultX, root.trMultY)
  }

  // Right edge (moving down)
  PathLine {
    relativeX: 0
    relativeY: root.panelHeight - root.trRadius * root.trMultY - root.brRadius * root.brMultY
  }

  // Bottom-right corner arc
  PathArc {
    relativeX: -root.brRadius * root.brMultX
    relativeY: root.brRadius * root.brMultY
    radiusX: root.brRadius
    radiusY: root.brRadius
    direction: root.getArcDirection(root.brMultX, root.brMultY)
  }

  // Bottom edge (moving left)
  PathLine {
    relativeX: -(root.panelWidth - root.brRadius * root.brMultX - root.blRadius * root.blMultX)
    relativeY: 0
  }

  // Bottom-left corner arc
  PathArc {
    relativeX: -root.blRadius * root.blMultX
    relativeY: -root.blRadius * root.blMultY
    radiusX: root.blRadius
    radiusY: root.blRadius
    direction: root.getArcDirection(root.blMultX, root.blMultY)
  }

  // Left edge (moving up) - closes the path back to start
  PathLine {
    relativeX: 0
    relativeY: -(root.panelHeight - root.blRadius * root.blMultY - root.tlRadius * root.tlMultY)
  }

  // Top-left corner arc (back to start)
  PathArc {
    relativeX: root.tlRadius * root.tlMultX
    relativeY: -root.tlRadius * root.tlMultY
    radiusX: root.tlRadius
    radiusY: root.tlRadius
    direction: root.getArcDirection(root.tlMultX, root.tlMultY)
  }

  Behavior on fillColor {
    ICAnim {}
  }
}
