pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.services
import qs.widgets

ColumnLayout {
  id: root

  required property PersistentProperties props
  required property Flickable container

  readonly property alias repeater: repeater

  anchors.left: parent.left
  anchors.right: parent.right
  spacing: Style.appearance.spacing.small

  Repeater {
    id: repeater

    model: ScriptModel {
      values: {
        const map = new Map();
        for (const n of NotificationService.notClosed)
          map.set(n.appName, null);
        for (const n of NotificationService.list)
          map.set(n.appName, null);
        return [...map.keys()];
      }
    }

    MouseArea {
      id: notif

      required property int index
      required property string modelData

      readonly property bool closed: notifInner.notifCount === 0
      property int startY

      function closeAll(): void {
        for (const n of NotificationService.notClosed.filter(n => n.appName === modelData))
          n.close();
      }

      Layout.fillWidth: true
      Layout.preferredHeight: notifInner.implicitHeight
      visible: !closed
      Layout.topMargin: index === 0 ? 0 : 0

      containmentMask: QtObject {
        function contains(p: point): bool {
          if (!root.container.contains(notif.mapToItem(root.container, p)))
            return false;
          return notifInner.contains(p);
        }
      }

      implicitWidth: root.width
      implicitHeight: notifInner.implicitHeight

      hoverEnabled: true
      cursorShape: pressed ? Qt.ClosedHandCursor : undefined
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      preventStealing: true
      enabled: !closed

      drag.target: this
      drag.axis: Drag.XAxis

      onPressed: event => {
        startY = event.y;
        if (event.button === Qt.RightButton)
          notifInner.toggleExpand(!notifInner.expanded);
        else if (event.button === Qt.MiddleButton)
          closeAll();
      }
      onPositionChanged: event => {
        if (pressed) {
          const diffY = event.y - startY;
          if (Math.abs(diffY) > Settings.notifications.expandThreshold)
            notifInner.toggleExpand(diffY > 0);
        }
      }
      onReleased: event => {
        if (Math.abs(x) < width * Settings.notifications.clearThreshold)
          x = 0;
        else
          closeAll();
      }

      ParallelAnimation {
        running: true

        IAnim {
          target: notif
          property: "opacity"
          from: 0
          to: 1
        }
        IAnim {
          target: notif
          property: "scale"
          from: 0
          to: 1
          duration: Style.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.appearance.anim.curves.expressiveDefaultSpatial
        }
      }

      ParallelAnimation {
        running: notif.closed

        IAnim {
          target: notif
          property: "opacity"
          to: 0
        }
        IAnim {
          target: notif
          property: "scale"
          to: 0.6
        }
      }

      NotificationGroup {
        id: notifInner

        modelData: notif.modelData
        props: root.props
        container: root.container
      }

      Behavior on x {
        IAnim {
          duration: Style.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.appearance.anim.curves.expressiveDefaultSpatial
        }
      }
    }
  }
}
