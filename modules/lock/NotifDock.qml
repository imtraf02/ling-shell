pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

ColumnLayout {
  id: root

  spacing: Style.spacing.small

  anchors.fill: parent
  anchors.margins: Style.padding.normal

  IText {
    Layout.fillWidth: true
    text: NotificationService.list.length > 0 ? `${NotificationService.list.length} notification


${NotificationService.list.length === 1 ? "" : "s"}` : "Notifications"
    color: ThemeService.palette.mOutline
    font.family: Settings.appearance.font.mono
    elide: Text.ElideRight
  }

  ClippingRectangle {
    id: clipRect

    Layout.fillWidth: true
    Layout.fillHeight: true

    radius: Style.rounding.small
    color: "transparent"

    Loader {
      anchors.centerIn: parent
      asynchronous: true
      active: opacity > 0
      opacity: NotificationService.list.length > 0 ? 0 : 1

      sourceComponent: ColumnLayout {
        spacing: Style.spacing.small

        IIcon {
          icon: "notifications"
          font.pointSize: Style.font.size.extraLarge
          Layout.alignment: Qt.AlignHCenter
          color: ThemeService.palette.mOutline
        }

        IText {
          Layout.alignment: Qt.AlignHCenter
          text: "No notifications"
          color: ThemeService.palette.mOutline
          font.pointSize: Style.font.size.large
          font.family: Settings.appearance.font.mono
        }
      }

      Behavior on opacity {
        IAnim {
          duration: Style.anim.durations.extraLarge
        }
      }
    }

    IListView {
      anchors.fill: parent

      spacing: Style.spacing.small
      clip: true

      model: ScriptModel {
        values: {
          const list = NotificationService.notClosed.map(n => [n.appName, null]);
          return [...new Map(list).keys()];
        }
      }

      delegate: NotifGroup {}

      add: Transition {
        IAnim {
          property: "opacity"
          from: 0
          to: 1
        }
        IAnim {
          property: "scale"
          from: 0
          to: 1
          duration: Style.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.anim.curves.expressiveDefaultSpatial
        }
      }

      remove: Transition {
        IAnim {
          property: "opacity"
          to: 0
        }
        IAnim {
          property: "scale"
          to: 0.6
        }
      }

      move: Transition {
        IAnim {
          properties: "opacity,scale"
          to: 1
        }
        IAnim {
          property: "y"
          duration: Style.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.anim.curves.expressiveDefaultSpatial
        }
      }

      displaced: Transition {
        IAnim {
          properties: "opacity,scale"
          to: 1
        }
        IAnim {
          property: "y"
          duration: Style.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.anim.curves.expressiveDefaultSpatial
        }
      }
    }
  }
}
