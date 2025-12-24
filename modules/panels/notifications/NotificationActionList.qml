pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

Item {
  id: root

  required property NotificationService.Notif notif

  Layout.fillWidth: true
  implicitHeight: flickable.contentHeight

  layer.enabled: true
  layer.smooth: true
  layer.effect: IOpacityMask {
    maskSource: gradientMask
  }

  Item {
    id: gradientMask

    anchors.fill: parent
    layer.enabled: true
    visible: false

    Rectangle {
      anchors.fill: parent

      gradient: Gradient {
        orientation: Gradient.Horizontal

        GradientStop {
          position: 0
          color: Qt.rgba(0, 0, 0, 0)
        }
        GradientStop {
          position: 0.1
          color: Qt.rgba(0, 0, 0, 1)
        }
        GradientStop {
          position: 0.9
          color: Qt.rgba(0, 0, 0, 1)
        }
        GradientStop {
          position: 1
          color: Qt.rgba(0, 0, 0, 0)
        }
      }
    }

    Rectangle {
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.left: parent.left

      implicitWidth: parent.width / 2
      opacity: flickable.contentX > 0 ? 0 : 1

      Behavior on opacity {
        IAnim {}
      }
    }

    Rectangle {
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.right: parent.right

      implicitWidth: parent.width / 2
      opacity: flickable.contentX < flickable.contentWidth - parent.width ? 0 : 1

      Behavior on opacity {
        IAnim {}
      }
    }
  }

  IFlickable {
    id: flickable

    anchors.fill: parent
    contentWidth: Math.max(width, actionList.implicitWidth)
    contentHeight: actionList.implicitHeight

    RowLayout {
      id: actionList

      anchors.fill: parent
      spacing: Config.appearance.spacing.small

      Repeater {
        model: [
          {
            isClose: true
          },
          ...root.notif.actions,
          {
            isCopy: true
          }
        ]

        Rectangle {
          id: action

          required property var modelData

          Layout.fillWidth: true
          Layout.fillHeight: true
          implicitWidth: actionInner.implicitWidth + Config.appearance.padding.normal * 2
          implicitHeight: actionInner.implicitHeight + Config.appearance.padding.small * 2

          Layout.preferredWidth: implicitWidth + (actionStateLayer.pressed ? Config.appearance.padding.large : 0)
          radius: actionStateLayer.pressed ? Config.appearance.rounding.small / 2 : Config.appearance.rounding.small
          color: ThemeService.palette.mSurfaceContainerHighest

          Timer {
            id: copyTimer

            interval: 3000
            onTriggered: actionInner.item.text = "content_copy"
          }

          IStateLayer {
            id: actionStateLayer

            function onClicked(): void {
              if (action.modelData.isClose) {
                root.notif.close();
              } else if (action.modelData.isCopy) {
                Quickshell.clipboardText = root.notif.body;
                actionInner.item.text = "inventory";
                copyTimer.start();
              } else if (action.modelData.invoke) {
                action.modelData.invoke();
              } else if (!root.notif.resident) {
                root.notif.close();
              }
            }
          }

          Loader {
            id: actionInner

            anchors.centerIn: parent
            sourceComponent: action.modelData.isClose || action.modelData.isCopy ? iconBtn : root.notif.hasActionIcons ? iconComp : textComp
          }

          Component {
            id: iconBtn

            IIcon {
              animate: action.modelData.isCopy ?? false
              icon: action.modelData.isCopy ? "content_copy" : "close"
              color: ThemeService.palette.mOnSurfaceVariant
            }
          }

          Component {
            id: iconComp

            IconImage {
              source: Quickshell.iconPath(action.modelData.identifier)
            }
          }

          Component {
            id: textComp

            IText {
              text: action.modelData.text
              color: ThemeService.palette.mOnSurfaceVariant
            }
          }

          Behavior on Layout.preferredWidth {
            IAnim {
              duration: Config.appearance.anim.durations.expressiveFastSpatial
              easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
            }
          }

          Behavior on radius {
            IAnim {
              duration: Config.appearance.anim.durations.expressiveFastSpatial
              easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
            }
          }
        }
      }
    }
  }
}
