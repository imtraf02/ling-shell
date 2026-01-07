import QtQuick
import qs.commons

ColorAnimation {
  duration: Style.appearance.anim.durations.normal
  easing.type: Easing.BezierSpline
  easing.bezierCurve: Style.appearance.anim.curves.standard
}
