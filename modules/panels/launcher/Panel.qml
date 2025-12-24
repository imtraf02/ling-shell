pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.commons
import qs.widgets
import qs.services

Item {
  id: root

  required property ShellScreen screen

  property bool shouldBeActive: false
  property int contentHeight
  readonly property real maxHeight: {
    let max = screen.height - Settings.appearance.thickness * 2 - Config.appearance.spacing.small;
    return max;
  }

  visible: height > 0
  implicitWidth: content.implicitWidth
  implicitHeight: 0
  clip: true

  signal opened

  function toggle(button) {
    shouldBeActive ? close() : open(button);
  }

  function close() {
    shouldBeActive = false;
    VisibilityService.closedPanel(root);
  }

  function open() {
    shouldBeActive = true;
    VisibilityService.willOpenPanel(root);
  }

  onShouldBeActiveChanged: {
    if (shouldBeActive) {
      timer.stop();
      hideAnim.stop();
      showAnim.start();
    } else {
      showAnim.stop();
      hideAnim.start();
    }
  }

  SequentialAnimation {
    id: showAnim

    IAnim {
      target: root
      property: "implicitHeight"
      to: root.contentHeight
      duration: Config.appearance.anim.durations.expressiveDefaultSpatial
      easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
    }
    ScriptAction {
      script: root.implicitHeight = Qt.binding(() => content.implicitHeight)
    }
  }

  SequentialAnimation {
    id: hideAnim

    ScriptAction {
      script: root.implicitHeight = root.implicitHeight
    }
    IAnim {
      target: root
      property: "implicitHeight"
      to: 0
      easing.bezierCurve: Config.appearance.anim.curves.emphasized
    }
  }

  Timer {
    id: timer

    interval: Config.appearance.anim.durations.extraLarge
    onRunningChanged: {
      if (running && !root.shouldBeActive) {
        content.visible = false;
        content.active = true;
      } else {
        root.contentHeight = Math.min(root.maxHeight, content.implicitHeight);
        content.active = Qt.binding(() => root.shouldBeActive || root.visible);
        content.visible = true;
        if (showAnim.running) {
          showAnim.stop();
          showAnim.start();
        }
      }
    }
  }

  Loader {
    id: content
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    visible: false
    active: false
    Component.onCompleted: timer.start()

    sourceComponent: Content {
      panel: root
      maxHeight: root.maxHeight
    }
  }
}
