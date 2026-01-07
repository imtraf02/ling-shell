pragma ComponentBehavior: Bound

import QtQuick
import qs.commons
import qs.services
import qs.widgets

Item {
  id: root

  property string text: ""
  property string icon: ""
  property string suffix: ""

  property bool autoHide: false
  property bool forceOpen: false
  property bool forceClose: false
  property bool oppositeDirection: false
  property bool hovered: false

  property bool showPill: false
  property bool shouldAnimateHide: false

  readonly property bool revealed: !forceClose && (forceOpen || showPill)

  readonly property int pillHeight: Style.bar.innerHeight
  readonly property int pillPadding: Math.round(Style.bar.innerHeight * 0.2)
  readonly property int pillOverlap: Math.round(Style.bar.innerHeight * 0.5)
  readonly property int pillMaxWidth: Math.max(1, Math.round(textItem.implicitWidth + pillPadding * 2 + pillOverlap))

  readonly property real textSize: Math.max(1, Math.round(pillHeight * 0.33))
  readonly property real iconSize: Math.max(1, Math.round(pillHeight * 0.48))

  signal shown
  signal hidden
  signal entered
  signal exited
  signal clicked
  signal rightClicked
  signal middleClicked
  signal wheel(int delta)

  width: root.pillHeight + Math.max(0, pill.width - pillOverlap)
  height: root.pillHeight
  clip: true

  Rectangle {
    id: pill

    width: root.revealed ? root.pillMaxWidth : 1
    height: root.pillHeight

    x: root.oppositeDirection ? (iconCircle.x + iconCircle.width / 2) : (iconCircle.x + iconCircle.width / 2) - width
    opacity: root.revealed ? 1 : 0
    color: root.hovered ? ThemeService.palette.mSurfaceContainerHigh : ThemeService.palette.mSurfaceContainer

    topLeftRadius: root.oppositeDirection ? 0 : Settings.appearance.cornerRadius
    bottomLeftRadius: root.oppositeDirection ? 0 : Settings.appearance.cornerRadius
    topRightRadius: root.oppositeDirection ? Settings.appearance.cornerRadius : 0
    bottomRightRadius: root.oppositeDirection ? Settings.appearance.cornerRadius : 0
    anchors.verticalCenter: parent.verticalCenter

    Behavior on width {
      enabled: showAnim.running || hideAnim.running
      IAnim {}
    }
    Behavior on opacity {
      enabled: showAnim.running || hideAnim.running
      IAnim {}
    }

    IText {
      id: textItem
      anchors.verticalCenter: parent.verticalCenter
      x: {
        var centerX = (parent.width - width) / 2;
        var offset = root.oppositeDirection ? Style.appearance.padding.small : -Style.appearance.padding.small;
        if (root.forceOpen) {
          // If its force open, the icon disc background is the same color as the bg pill move text slightly
          offset += root.oppositeDirection ? -Style.appearance.padding.small : Style.appearance.padding.small;
        }
        return centerX + offset;
      }
      text: root.text + root.suffix
      pointSize: root.textSize
      color: ThemeService.palette.mPrimary
      visible: root.revealed
    }
  }

  Rectangle {
    id: iconCircle

    width: root.pillHeight
    height: root.pillHeight

    radius: Settings.appearance.cornerRadius
    color: pill.color
    anchors.verticalCenter: parent.verticalCenter

    x: root.oppositeDirection ? 0 : (parent.width - width)

    Behavior on color {
      ICAnim {}
    }

    IIcon {
      icon: root.icon
      pointSize: root.iconSize
      color: ThemeService.palette.mPrimary
      x: (iconCircle.width - width) / 2
      y: (iconCircle.height - height) / 2 + (height - contentHeight) / 2
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onEntered: {
      root.hovered = true;
      root.entered();
      if (root.forceClose) {
        return;
      }
      if (!root.forceOpen) {
        root.showDelayed();
      }
    }
    onExited: {
      root.hovered = false;
      root.exited();
      if (!root.forceOpen && !root.forceClose) {
        root.hide();
      }
    }
    onClicked: function (mouse) {
      if (mouse.button === Qt.LeftButton) {
        root.clicked();
      } else if (mouse.button === Qt.RightButton) {
        root.rightClicked();
      } else if (mouse.button === Qt.MiddleButton) {
        root.middleClicked();
      }
    }
    onWheel: wheel => root.wheel(wheel.angleDelta.y)
  }

  Timer {
    id: showTimer
    interval: Settings.delay.pill
    onTriggered: {
      if (!root.showPill) {
        showAnim.start();
      }
    }
  }

  function show() {
    if (!root.showPill) {
      shouldAnimateHide = autoHide;
      showAnim.start();
    } else {
      hideAnim.stop();
      delayedHideAnim.restart();
    }
  }

  function hide() {
    if (forceOpen) {
      return;
    }
    if (showPill) {
      hideAnim.start();
    }
    showTimer.stop();
  }

  function showDelayed() {
    if (!showPill) {
      shouldAnimateHide = autoHide;
      showTimer.start();
    } else {
      hideAnim.stop();
      delayedHideAnim.restart();
    }
  }

  ParallelAnimation {
    id: showAnim
    running: false
    NumberAnimation {
      target: pill
      property: "width"
      from: 1
      to: root.pillMaxWidth
      duration: Style.appearance.anim.durations.normal
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: pill
      property: "opacity"
      from: 0
      to: 1
      duration: Style.appearance.anim.durations.normal
      easing.type: Easing.OutCubic
    }
    onStarted: {
      root.showPill = true;
    }
    onStopped: {
      delayedHideAnim.start();
      root.shown();
    }
  }

  SequentialAnimation {
    id: delayedHideAnim
    running: false
    PauseAnimation {
      duration: 2500
    }
    ScriptAction {
      script: if (shouldAnimateHide) {
        hideAnim.start();
      }
    }
  }

  ParallelAnimation {
    id: hideAnim
    running: false
    NumberAnimation {
      target: pill
      property: "width"
      from: root.pillMaxWidth
      to: 1
      duration: Style.appearance.anim.durations.normal
      easing.type: Easing.InCubic
    }
    NumberAnimation {
      target: pill
      property: "opacity"
      from: 1
      to: 0
      duration: Style.appearance.anim.durations.normal
      easing.type: Easing.InCubic
    }
    onStopped: {
      root.showPill = false;
      root.shouldAnimateHide = false;
      root.hidden();
    }
  }
}
