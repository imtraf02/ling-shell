import QtQuick
import qs.config
import qs.services

Rectangle {
  required property int extra

  anchors.right: parent.right
  anchors.margins: Config.appearance.padding.normal

  color: ThemeService.palette.mTertiary
  radius: Config.appearance.rounding.small

  implicitWidth: count.implicitWidth + Config.appearance.padding.normal * 2
  implicitHeight: count.implicitHeight + Config.appearance.padding.small * 2

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
      duration: Config.appearance.anim.durations.expressiveFastSpatial
    }
  }

  Behavior on scale {
    IAnim {
      duration: Config.appearance.anim.durations.expressiveFastSpatial
      easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
    }
  }
}
