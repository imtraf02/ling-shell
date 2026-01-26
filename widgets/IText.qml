import QtQuick
import qs.common
import qs.services
import qs.widgets

Text {
  id: root

  property bool animate: false
  property string animateProp: "scale"
  property real animateFrom: 0
  property real animateTo: 1
  property int animateDuration: Style.anim.durations.normal

  font.family: Settings.appearance.font.sans
  font.pointSize: Style.font.size.normal
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
        easing.bezierCurve: Style.anim.curves.standardAccel
      }
      PropertyAction {}
      Anim {
        to: root.animateTo
        easing.bezierCurve: Style.anim.curves.standardDecel
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
