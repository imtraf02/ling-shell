pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets
import qs.services

ColumnLayout {
  id: root

  required property PersistentProperties props
  required property list<var> notifs
  required property bool expanded
  required property Flickable container

  readonly property int spacing: Math.round(Config.appearance.spacing.small / 2)
  property bool showAllNotifs
  property bool flag

  signal requestToggleExpand(expand: bool)

  onExpandedChanged: {
    if (expanded) {
      clearTimer.stop();
      showAllNotifs = true;
    } else {
      clearTimer.start();
    }
  }

  Layout.fillWidth: true

  Timer {
    id: clearTimer
    interval: Config.appearance.anim.durations.normal
    onTriggered: root.showAllNotifs = false
  }

  Repeater {
    id: repeater
    model: ScriptModel {
      values: root.showAllNotifs ? root.notifs : root.notifs.slice(0, Config.notifications.groupPreviewNum + 1)
      onValuesChanged: root.flagChanged()
    }

    MouseArea {
      id: notif

      required property int index
      required property NotificationService.Notif modelData

      readonly property bool previewHidden: {
        if (root.expanded)
          return false;
        let extraHidden = 0;
        for (let i = 0; i < index; i++)
          if (root.notifs[i].closed)
            extraHidden++;
        return index >= Config.notifications.groupPreviewNum + extraHidden;
      }

      property int startY

      Layout.fillWidth: true
      Layout.preferredHeight: (modelData.closed || previewHidden) ? 0 : notifInner.implicitHeight
      Layout.topMargin: (index > 0 && (modelData.closed || previewHidden)) ? -root.spacing : 0

      clip: true
      visible: Layout.preferredHeight > 0 || opacity > 0

      opacity: previewHidden ? 0 : 1
      scale: previewHidden ? 0.7 : 1

      implicitWidth: root.width
      implicitHeight: notifInner.implicitHeight

      hoverEnabled: true
      cursorShape: notifInner.body?.hoveredLink ? Qt.PointingHandCursor : pressed ? Qt.ClosedHandCursor : undefined

      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      preventStealing: !root.expanded
      enabled: !modelData.closed

      drag.target: this
      drag.axis: Drag.XAxis

      onPressed: event => {
        startY = event.y;
        if (event.button === Qt.RightButton)
          root.requestToggleExpand(!root.expanded);
        else if (event.button === Qt.MiddleButton)
          modelData.close();
      }

      onPositionChanged: event => {
        if (pressed && !root.expanded) {
          const diffY = event.y - startY;
          if (Math.abs(diffY) > Config.notifications.expandThreshold)
            root.requestToggleExpand(diffY > 0);
        }
      }

      onReleased: event => {
        if (Math.abs(x) < width * Config.notifications.clearThreshold)
          x = 0;
        else
          modelData.close();
      }

      Component.onCompleted: modelData.lock(this)
      Component.onDestruction: modelData.unlock(this)

      ParallelAnimation {
        Component.onCompleted: running = !notif.previewHidden
        IAnim {
          target: notif
          property: "opacity"
          from: 0
          to: 1
        }
        IAnim {
          target: notif
          property: "scale"
          from: 0.7
          to: 1
        }
      }

      ParallelAnimation {
        running: notif.modelData.closed
        onFinished: notif.modelData.unlock(notif)
        IAnim {
          target: notif
          property: "opacity"
          to: 0
        }
        IAnim {
          target: notif
          property: "x"
          to: notif.x >= 0 ? notif.width : -notif.width
        }
      }

      Notification {
        id: notifInner
        anchors.fill: parent
        modelData: notif.modelData
        props: root.props
        expanded: root.expanded
      }

      Behavior on Layout.preferredHeight {
        IAnim {
          duration: Config.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
        }
      }

      Behavior on Layout.topMargin {
        IAnim {
          duration: Config.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
        }
      }

      Behavior on opacity {
        IAnim {}
      }
      Behavior on scale {
        IAnim {}
      }

      Behavior on x {
        IAnim {
          duration: Config.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
        }
      }
    }
  }
}
