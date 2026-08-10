pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

Shape {
  id: root

  required property Item bar

  anchors.fill: parent

  preferredRendererType: Shape.CurveRenderer

  ShapePath {
    fillColor: ThemeService.palette.mSurface
    strokeWidth: -1
    fillRule: ShapePath.OddEvenFill

    PathRectangle {
      x: 0
      y: 0
      width: root.width
      height: root.height
    }

    PathRectangle {
      x: Settings.appearance.thickness
      y: root.bar.implicitHeight
      width: Math.max(0, root.width - Settings.appearance.thickness * 2)
      height: Math.max(0, root.height - root.bar.implicitHeight - Settings.appearance.thickness)
      radius: Settings.appearance.cornerRadius
    }
  }
}
