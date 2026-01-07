pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.commons
import qs.services
import qs.widgets

ColumnLayout {
  id: root

  readonly property real padding: Style.appearance.padding.normal
  spacing: Style.appearance.spacing.small

  anchors.fill: parent
  anchors.margins: padding

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

    radius: Settings.appearance.cornerRadius
    color: "transparent"

    Loader {
      anchors.centerIn: parent
      asynchronous: true
      active: opacity > 0
      opacity: NotificationService.list.length > 0 ? 0 : 1

      sourceComponent: ColumnLayout {
        spacing: root.spacing

        Image {
          asynchronous: true
          source: Qt.resolvedUrl(Settings.notifications.background)
          fillMode: Image.PreserveAspectFit
          sourceSize.height: clipRect.implicitHeight * 0.8

          layer.enabled: true
          layer.effect: IColouriser {
            colorizationColor: ThemeService.palette.mOutline
            brightness: 1
          }
        }

        IText {
          Layout.alignment: Qt.AlignHCenter
          text: "No notifications"
          color: ThemeService.palette.mOutline
          font.pointSize: Style.appearance.font.size.large
          font.family: Settings.appearance.font.mono
        }
      }

      Behavior on opacity {
        IAnim {
          duration: Style.appearance.anim.durations.extraLarge
        }
      }
    }

    IListView {
      anchors.fill: parent

      spacing: root.spacing
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
          duration: Style.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.appearance.anim.curves.expressiveDefaultSpatial
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
          duration: Style.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.appearance.anim.curves.expressiveDefaultSpatial
        }
      }

      displaced: Transition {
        IAnim {
          properties: "opacity,scale"
          to: 1
        }
        IAnim {
          property: "y"
          duration: Style.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.appearance.anim.curves.expressiveDefaultSpatial
        }
      }
    }
  }
}
