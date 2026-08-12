pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.widgets
import qs.services

ColumnLayout {
  id: root

  required property PersistentProperties props
  required property list<var> notifs
  required property bool expanded
  required property Flickable container

  readonly property int spacing: Math.round(Style.spacing.small / 2)
  property bool showAllNotifs
  property bool visualExpanded
  readonly property bool collapsing: showAllNotifs && !expanded
  property bool flag

  signal requestToggleExpand(expand: bool)

  onExpandedChanged: {
    if (expanded) {
      showAllNotifs = true;
      Qt.callLater(() => {
        if (root.expanded)
          root.visualExpanded = true;
      });
    } else {
      visualExpanded = false;
      Qt.callLater(finishCollapseIfReady);
    }
  }

  Component.onCompleted: {
    if (expanded) {
      showAllNotifs = true;
      visualExpanded = true;
    }
  }

  Layout.fillWidth: true

  function finishCollapseIfReady(): void {
    if (!collapsing)
      return;

    for (let i = 0; i < repeater.count; i++) {
      const item = repeater.itemAt(i);
      if (item?.previewHidden && item.animatedHeight > 0.5)
        return;
    }

    showAllNotifs = false;
  }

  Repeater {
    id: repeater
    model: ScriptModel {
      values: {
        if (root.showAllNotifs)
          return root.notifs;

        let activeCount = 0;
        return root.notifs.filter(notif => {
          if (notif.closed)
            return true;
          return activeCount++ < Settings.notifications.groupPreviewNum;
        });
      }
      onValuesChanged: root.flagChanged()
    }

    MouseArea {
      id: notif

      required property int index
      required property NotificationService.Notif modelData

      readonly property bool previewHidden: {
        if (root.visualExpanded)
          return false;
        let extraHidden = 0;
        for (let i = 0; i < index; i++)
          if (root.notifs[i].closed)
            extraHidden++;
        return index >= Settings.notifications.groupPreviewNum + extraHidden;
      }
      readonly property real targetHeight: (modelData.closed || previewHidden) ? 0 : notifInner.implicitHeight
      property real animatedHeight: targetHeight

      property int startY

      Layout.fillWidth: true
      // The expressive easing overshoots. Clamp the value so a negative
      // preferredHeight is never interpreted by Qt Layout as "unset".
      Layout.preferredHeight: Math.max(0, animatedHeight)
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
          if (Math.abs(diffY) > Settings.notifications.expandThreshold)
            root.requestToggleExpand(diffY > 0);
        }
      }

      onReleased: event => {
        if (Math.abs(x) < width * Settings.notifications.clearThreshold)
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
        // Load expanded content before revealing its height, and keep hidden
        // delegates expanded until their collapse animation has completed.
        expanded: root.expanded || (root.collapsing && notif.previewHidden)
      }

      Behavior on animatedHeight {
        IAnim {
          duration: Style.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.anim.curves.expressiveDefaultSpatial

          onRunningChanged: {
            if (!running)
              Qt.callLater(root.finishCollapseIfReady);
          }
        }
      }

      Behavior on Layout.topMargin {
        IAnim {
          duration: Style.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.anim.curves.expressiveDefaultSpatial
        }
      }

      Behavior on opacity {
        IAnim {
          duration: Style.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.anim.curves.expressiveDefaultSpatial
        }
      }
      Behavior on scale {
        IAnim {
          duration: Style.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.anim.curves.expressiveDefaultSpatial
        }
      }

      Behavior on x {
        IAnim {
          duration: Style.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.anim.curves.expressiveDefaultSpatial
        }
      }
    }
  }
}
