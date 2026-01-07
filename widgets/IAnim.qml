import QtQuick
import qs.commons

NumberAnimation {
  duration: Style.appearance.anim.durations.normal
  easing.type: Easing.BezierSpline
  easing.bezierCurve: Style.appearance.anim.curves.standard
}
