import QtQuick
import qs.common

NumberAnimation {
  duration: Style.anim.durations.normal
  easing.type: Easing.BezierSpline
  easing.bezierCurve: Style.anim.curves.standard
}
