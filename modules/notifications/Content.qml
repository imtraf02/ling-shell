import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.commons
import qs.services
import qs.widgets

Item {
  id: root

  readonly property int padding: Config.appearance.padding.normal

  anchors.top: parent.top
  anchors.bottom: parent.bottom
  anchors.right: parent.right

  implicitWidth: Config.notifications.sizes.width + padding * 2
  implicitHeight: {
    const count = list.count;
    if (count === 0)
      return 0;

    let height = (count - 1) * Config.appearance.spacing.small;
    for (let i = 0; i < count; i++)
      height += list.itemAtIndex(i)?.nonAnimHeight ?? 0;

    return Math.min((QsWindow.window?.screen?.height ?? 0) - Settings.appearance.thickness * 2, height + padding * 2);
  }

  ClippingWrapperRectangle {
    anchors.fill: parent
    anchors.margins: root.padding

    color: "transparent"
    radius: Settings.appearance.cornerRadius

    IListView {
      id: list

      model: ScriptModel {
        values: NotificationService.popups.filter(n => !n.closed)
      }

      anchors.fill: parent

      orientation: Qt.Vertical
      spacing: 0
      cacheBuffer: QsWindow.window?.screen.height ?? 0

      delegate: Item {
        id: wrapper

        required property NotificationService.Notif modelData
        required property int index
        readonly property alias nonAnimHeight: notif.nonAnimHeight
        property int idx

        onIndexChanged: {
          if (index !== -1)
            idx = index;
        }

        implicitWidth: notif.implicitWidth
        implicitHeight: notif.implicitHeight + (idx === 0 ? 0 : Config.appearance.spacing.small)

        ListView.onRemove: removeAnim.start()

        SequentialAnimation {
          id: removeAnim

          PropertyAction {
            target: wrapper
            property: "ListView.delayRemove"
            value: true
          }
          PropertyAction {
            target: wrapper
            property: "enabled"
            value: false
          }
          PropertyAction {
            target: wrapper
            property: "implicitHeight"
            value: 0
          }
          PropertyAction {
            target: wrapper
            property: "z"
            value: 1
          }
          IAnim {
            target: notif
            property: "x"
            to: (notif.x >= 0 ? Config.notifications.sizes.width : -Config.notifications.sizes.width) * 2
            duration: Config.appearance.anim.durations.normal
            easing.bezierCurve: Config.appearance.anim.curves.emphasized
          }
          PropertyAction {
            target: wrapper
            property: "ListView.delayRemove"
            value: false
          }
        }

        ClippingRectangle {
          anchors.top: parent.top
          anchors.topMargin: wrapper.idx === 0 ? 0 : Config.appearance.spacing.small

          color: "transparent"
          radius: notif.radius
          implicitWidth: notif.implicitWidth
          implicitHeight: notif.implicitHeight

          Notification {
            id: notif

            modelData: wrapper.modelData
          }
        }
      }

      move: Transition {
        IAnim {
          property: "y"
        }
      }

      displaced: Transition {
        IAnim {
          property: "y"
        }
      }

      IExtraIndicator {
        anchors.top: parent.top
        extra: {
          const count = list.count;
          if (count === 0)
            return 0;

          const scrollY = list.contentY;

          let height = 0;
          for (let i = 0; i < count; i++) {
            height += (list.itemAtIndex(i)?.nonAnimHeight ?? 0) + Config.appearance.spacing.small;

            if (height - Config.appearance.spacing.small >= scrollY)
              return i;
          }

          return count;
        }
      }

      IExtraIndicator {
        anchors.bottom: parent.bottom
        extra: {
          const count = list.count;
          if (count === 0)
            return 0;

          const scrollY = list.contentHeight - (list.contentY + list.height);

          let height = 0;
          for (let i = count - 1; i >= 0; i--) {
            height += (list.itemAtIndex(i)?.nonAnimHeight ?? 0) + Config.appearance.spacing.small;

            if (height - Config.appearance.spacing.small >= scrollY)
              return count - i - 1;
          }

          return 0;
        }
      }
    }
  }

  Behavior on implicitHeight {
    Anim {}
  }

  component Anim: NumberAnimation {
    duration: Config.appearance.anim.durations.expressiveDefaultSpatial
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
  }
}
