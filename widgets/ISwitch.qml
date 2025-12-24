import QtQuick
import QtQuick.Templates
import QtQuick.Shapes
import qs.config
import qs.commons
import qs.services

Switch {
  id: root

  implicitWidth: implicitIndicatorWidth
  implicitHeight: implicitIndicatorHeight

  indicator: Rectangle {
    radius: Settings.appearance.cornerRadius
    color: root.checked ? ThemeService.palette.mPrimary : ThemeService.palette.mSurfaceContainerHighest

    implicitWidth: implicitHeight * 2
    implicitHeight: Config.appearance.font.size.normal + Config.appearance.padding.smaller * 2

    Rectangle {
      readonly property real nonAnimWidth: root.pressed ? implicitHeight * 1.3 : implicitHeight

      radius: Settings.appearance.cornerRadius
      color: root.checked ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOutline

      x: root.checked ? parent.implicitWidth - nonAnimWidth - Config.appearance.padding.small / 2 : Config.appearance.padding.small / 2
      implicitWidth: nonAnimWidth
      implicitHeight: parent.implicitHeight - Config.appearance.padding.small
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        anchors.fill: parent
        radius: parent.radius

        color: root.checked ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurface
        opacity: root.pressed ? 0.1 : root.hovered ? 0.08 : 0

        Behavior on opacity {
          IAnim {}
        }
      }

      Shape {
        id: icon

        property point start1: {
          if (root.pressed)
            return Qt.point(width * 0.2, height / 2);
          if (root.checked)
            return Qt.point(width * 0.15, height / 2);
          return Qt.point(width * 0.15, height * 0.15);
        }
        property point end1: {
          if (root.pressed) {
            if (root.checked)
              return Qt.point(width * 0.4, height / 2);
            return Qt.point(width * 0.8, height / 2);
          }
          if (root.checked)
            return Qt.point(width * 0.4, height * 0.7);
          return Qt.point(width * 0.85, height * 0.85);
        }
        property point start2: {
          if (root.pressed) {
            if (root.checked)
              return Qt.point(width * 0.4, height / 2);
            return Qt.point(width * 0.2, height / 2);
          }
          if (root.checked)
            return Qt.point(width * 0.4, height * 0.7);
          return Qt.point(width * 0.15, height * 0.85);
        }
        property point end2: {
          if (root.pressed)
            return Qt.point(width * 0.8, height / 2);
          if (root.checked)
            return Qt.point(width * 0.85, height * 0.2);
          return Qt.point(width * 0.85, height * 0.15);
        }

        anchors.centerIn: parent
        width: height
        height: parent.implicitHeight - Config.appearance.padding.small * 2
        preferredRendererType: Shape.CurveRenderer
        asynchronous: true

        ShapePath {
          strokeWidth: Config.appearance.font.size.larger * 0.15
          strokeColor: root.checked ? ThemeService.palette.mPrimary : ThemeService.palette.mSurfaceContainerHighest
          fillColor: "transparent"
          capStyle: ShapePath.RoundCap

          startX: icon.start1.x
          startY: icon.start1.y

          PathLine {
            x: icon.end1.x
            y: icon.end1.y
          }
          PathMove {
            x: icon.start2.x
            y: icon.start2.y
          }
          PathLine {
            x: icon.end2.x
            y: icon.end2.y
          }

          Behavior on strokeColor {
            ICAnim {}
          }
        }

        Behavior on start1 {
          PropAnim {}
        }
        Behavior on end1 {
          PropAnim {}
        }
        Behavior on start2 {
          PropAnim {}
        }
        Behavior on end2 {
          PropAnim {}
        }
      }

      Behavior on x {
        IAnim {}
      }

      Behavior on implicitWidth {
        IAnim {}
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    enabled: false
  }

  component PropAnim: PropertyAnimation {
    duration: Config.appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Config.appearance.anim.curves.standard
  }
}
