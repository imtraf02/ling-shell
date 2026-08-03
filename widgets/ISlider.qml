import QtQuick
import QtQuick.Controls
import qs.common
import qs.services

/**
 * Compact Material 3 slider, following end4's StyledSlider geometry:
 * a thick rounded track, a small gap around the thin handle, and a round
 * stop indicator at the end of the range.
 */
Slider {
  id: root

  property list<real> stopIndicatorValues: [1]
  property bool snapAlways: true
  property real heightRatio: 0.7
  property bool hovering: false

  readonly property real sizeScale: Math.max(0.5, heightRatio / 0.7)
  readonly property real trackWidth: Math.max(4, Math.round(18 * sizeScale))
  readonly property real trackRadius: trackWidth >= 42 ? 21 : trackWidth >= 30 ? 12 : trackWidth >= 18 ? 6 : trackWidth / 2
  readonly property real unsharpenRadius: Math.min(trackWidth / 2, 2)
  readonly property real handleHeight: Math.max(33, trackWidth + 9)
  readonly property real handleDefaultWidth: 3
  readonly property real handlePressedWidth: 1.5
  readonly property real handleWidth: root.pressed ? handlePressedWidth : handleDefaultWidth
  readonly property real handleMargins: 4
  readonly property real effectiveDraggingWidth: Math.max(0, root.width - root.leftPadding - root.rightPadding)
  readonly property real trackDotSize: 3

  property color highlightColor: root.enabled ? ThemeService.palette.mPrimary : Qt.alpha(ThemeService.palette.mOnSurface, 0.38)
  property color trackColor: root.enabled ? ThemeService.palette.mSurfaceVariant : Qt.alpha(ThemeService.palette.mOnSurface, 0.12)
  property color handleColor: root.enabled ? ThemeService.palette.mPrimary : Qt.alpha(ThemeService.palette.mOnSurface, 0.38)
  property color dotColor: root.enabled ? ThemeService.palette.mOnSurfaceVariant : Qt.alpha(ThemeService.palette.mOnSurface, 0.38)
  property color dotColorHighlighted: root.enabled ? ThemeService.palette.mOnPrimary : Qt.alpha(ThemeService.palette.mOnSurface, 0.38)

  leftPadding: handleMargins
  rightPadding: handleMargins
  snapMode: snapAlways ? Slider.SnapAlways : Slider.SnapOnRelease
  implicitWidth: Style.widget.sliderWidth
  implicitHeight: handleHeight

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor

    onEntered: root.hovering = root.enabled
    onExited: root.hovering = false
    onPressed: mouse => mouse.accepted = false
  }

  background: Item {
    id: background

    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    width: root.width
    implicitWidth: Style.widget.sliderWidth
    implicitHeight: root.trackWidth
    height: implicitHeight

    Rectangle {
      id: activeTrack

      x: 0
      y: 0
      width: Math.max(0, root.visualPosition * root.effectiveDraggingWidth - root.handleWidth / 2)
      height: parent.height
      color: root.highlightColor
      topLeftRadius: root.trackRadius
      bottomLeftRadius: root.trackRadius
      topRightRadius: root.unsharpenRadius
      bottomRightRadius: root.unsharpenRadius
    }

    Rectangle {
      id: inactiveTrack

      x: root.leftPadding + root.visualPosition * root.effectiveDraggingWidth + root.handleWidth / 2 + root.handleMargins
      y: 0
      width: Math.max(0, (1 - root.visualPosition) * root.effectiveDraggingWidth - root.handleWidth / 2)
      height: parent.height
      color: root.trackColor
      topLeftRadius: root.unsharpenRadius
      bottomLeftRadius: root.unsharpenRadius
      topRightRadius: root.trackRadius
      bottomRightRadius: root.trackRadius
    }

    Repeater {
      model: root.stopIndicatorValues

      delegate: Rectangle {
        required property real modelData

        readonly property real normalizedValue: (modelData - root.from) / (root.to - root.from)

        x: root.leftPadding + normalizedValue * root.effectiveDraggingWidth - root.trackDotSize / 2
        y: parent.height / 2 - height / 2
        width: root.trackDotSize
        height: root.trackDotSize
        radius: width / 2
        color: normalizedValue > root.visualPosition ? root.dotColor : root.dotColorHighlighted

        Behavior on color {
          ColorAnimation {
            duration: 120
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Style.anim.curves.standardDecel
          }
        }
      }
    }
  }

  handle: Rectangle {
    id: handle

    implicitWidth: root.handleWidth
    implicitHeight: root.handleHeight
    x: root.leftPadding + root.visualPosition * root.effectiveDraggingWidth - root.handleWidth / 2
    anchors.verticalCenter: parent.verticalCenter
    radius: width / 2
    color: root.handleColor

    Behavior on implicitWidth {
      NumberAnimation {
        duration: 120
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Style.anim.curves.standardDecel
      }
    }
  }
}
