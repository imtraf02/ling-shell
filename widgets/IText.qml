pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.commons
import qs.services

Text {
  id: root

  property string family: Settings.appearance.font.sans
  property real pointSize: Config.appearance.font.size.normal
  property int weight: Settings.appearance.font.weight

  property bool animate: false
  property string animateProp: "scale"
  property real animateFrom: 0
  property real animateTo: 1
  property int animateDuration: Config.appearance.anim.durations.normal

  font.family: root.family
  font.weight: root.weight
  font.pointSize: root.pointSize * Settings.appearance.font.scale
  color: ThemeService.palette.mOnSurface
  elide: Text.ElideRight
  wrapMode: Text.NoWrap
  verticalAlignment: Text.AlignVCenter
  antialiasing: true

  Behavior on color {
    ICAnim {}
  }

  Behavior on text {
    enabled: root.animate

    SequentialAnimation {
      Anim {
        to: root.animateFrom
        easing.bezierCurve: Config.appearance.anim.curves.standardAccel
      }
      PropertyAction {}
      Anim {
        to: root.animateTo
        easing.bezierCurve: Config.appearance.anim.curves.standardDecel
      }
    }
  }

  component Anim: NumberAnimation {
    target: root
    property: root.animateProp
    duration: root.animateDuration / 2
    easing.type: Easing.BezierSpline
  }
}
