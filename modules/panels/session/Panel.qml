pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.commons
import qs.widgets
import qs.services

Item {
  id: root
  required property ShellScreen screen
  property bool shouldBeActive: false
  property int contentWidth

  visible: width > 0
  implicitWidth: 0
  implicitHeight: content.implicitHeight
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
      property: "implicitWidth"
      to: root.contentWidth
      duration: Style.appearance.anim.durations.expressiveDefaultSpatial
      easing.bezierCurve: Style.appearance.anim.curves.expressiveDefaultSpatial
    }
    ScriptAction {
      script: root.implicitWidth = Qt.binding(() => content.implicitWidth)
    }
  }

  SequentialAnimation {
    id: hideAnim
    ScriptAction {
      script: root.implicitWidth = root.implicitWidth
    }
    IAnim {
      target: root
      property: "implicitWidth"
      to: 0
      easing.bezierCurve: Style.appearance.anim.curves.emphasized
    }
  }

  Timer {
    id: timer
    interval: Style.appearance.anim.durations.extraLarge
    onRunningChanged: {
      if (running && !root.shouldBeActive) {
        content.visible = false;
        content.active = true;
      } else {
        root.contentWidth = content.implicitWidth;
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
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    visible: false
    active: false
    Component.onCompleted: timer.start()
    sourceComponent: Content {
      panel: root
    }
  }
}
