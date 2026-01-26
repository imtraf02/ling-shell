import QtQuick
import qs.common
import qs.services

Rectangle {
  required property int extra

  anchors.right: parent.right
  anchors.margins: Style.padding.normal

  color: ThemeService.palette.mTertiary
  radius: Style.rounding.small

  implicitWidth: count.implicitWidth + Style.padding.normal * 2
  implicitHeight: count.implicitHeight + Style.padding.small * 2

  opacity: extra > 0 ? 1 : 0
  scale: extra > 0 ? 1 : 0.5

  IElevation {
    anchors.fill: parent
    radius: parent.radius
    opacity: parent.opacity
    z: -1
    level: 2
  }

  IText {
    id: count

    anchors.centerIn: parent
    animate: parent.opacity > 0
    text: `+${parent.extra}`
    color: ThemeService.palette.mOnTertiary
  }

  Behavior on opacity {
    IAnim {
      duration: Style.anim.durations.expressiveFastSpatial
    }
  }

  Behavior on scale {
    IAnim {
      duration: Style.anim.durations.expressiveFastSpatial
      easing.bezierCurve: Style.anim.curves.expressiveFastSpatial
    }
  }
}
