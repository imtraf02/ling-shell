import QtQuick
import QtQuick.Controls
import qs.config
import qs.services

Slider {
  id: root

  property var cutoutColor: ThemeService.palette.mSurface
  property bool snapAlways: true
  property real heightRatio: 0.7
  property bool hovering: false

  readonly property real knobDiameter: Math.round((Config.appearance.widget.size * heightRatio) / 2) * 2
  readonly property real trackHeight: Math.round((knobDiameter * 0.4) / 2) * 2
  readonly property real cutoutExtra: Math.round((Config.appearance.widget.size * 0.1) / 2) * 2

  padding: cutoutExtra / 2
  snapMode: snapAlways ? Slider.SnapAlways : Slider.SnapOnRelease
  implicitHeight: Math.max(trackHeight, knobDiameter)

  background: Rectangle {
    x: root.leftPadding
    y: root.topPadding + root.availableHeight / 2 - height / 2
    implicitWidth: Config.appearance.widget.sliderWidth
    implicitHeight: root.trackHeight
    width: root.availableWidth
    height: implicitHeight
    radius: height / 2
    color: Qt.alpha(ThemeService.palette.mSurface, 0.5)
    border.color: Qt.alpha(ThemeService.palette.mOutline, 0.5)
    border.width: 2

    // Active track with rounded leading edge and animated gradient
    Item {
      id: activeTrackContainer
      width: root.visualPosition * parent.width
      height: parent.height

      // Rounded start cap
      Rectangle {
        width: parent.height
        height: parent.height
        radius: width / 2
        color: Qt.darker(ThemeService.palette.mPrimary, 1.2)
      }

      // Main active track with gradient
      Rectangle {
        x: parent.height / 2
        width: parent.width - x
        height: parent.height
        radius: 0

        gradient: Gradient {
          orientation: Gradient.Horizontal

          GradientStop {
            position: 0.0
            color: Qt.darker(ThemeService.palette.mPrimary, 1.2)
            Behavior on color {
              ColorAnimation {
                duration: 300
              }
            }
          }

          GradientStop {
            position: 0.5
            color: ThemeService.palette.mPrimary
            SequentialAnimation on position {
              loops: Animation.Infinite
              NumberAnimation {
                from: 0.3
                to: 0.7
                duration: 2000
                easing.type: Easing.InOutSine
              }
              NumberAnimation {
                from: 0.7
                to: 0.3
                duration: 2000
                easing.type: Easing.InOutSine
              }
            }
          }

          GradientStop {
            position: 1.0
            color: Qt.lighter(ThemeService.palette.mPrimary, 1.2)
          }
        }
      }
    }

    // Circular cutout behind the knob
    Rectangle {
      id: knobCutout
      implicitWidth: root.knobDiameter + root.cutoutExtra
      implicitHeight: root.knobDiameter + root.cutoutExtra
      radius: width / 2
      color: root.cutoutColor !== undefined ? root.cutoutColor : ThemeService.palette.mSurface
      x: root.leftPadding + root.visualPosition * (root.availableWidth - root.knobDiameter) - cutoutExtra
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  handle: Item {
    implicitWidth: root.knobDiameter
    implicitHeight: root.knobDiameter
    x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
      id: knob
      implicitWidth: root.knobDiameter
      implicitHeight: root.knobDiameter
      radius: width / 2
      color: root.pressed ? ThemeService.palette.mPrimary : ThemeService.palette.mSurface
      border.color: ThemeService.palette.mPrimary
      border.width: 3
      anchors.centerIn: parent

      Behavior on color {
        ICAnim {}
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
      propagateComposedEvents: true

      onEntered: {
        root.hovering = true;
      }

      onExited: {
        root.hovering = false;
      }
    }
  }
}
