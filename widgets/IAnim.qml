import QtQuick
import qs.config

NumberAnimation {
  duration: Config.appearance.anim.durations.normal
  easing.type: Easing.BezierSpline
  easing.bezierCurve: Config.appearance.anim.curves.standard
}
