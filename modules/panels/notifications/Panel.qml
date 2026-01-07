pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.commons
import qs.widgets
import qs.services
import ".."

BarPanel {
  id: root

  readonly property int notifCount: NotificationService.list.reduce((acc, n) => n.closed ? acc : acc + 1, 0)

  PersistentProperties {
    id: props
    property list<string> expandedNotifs: []

    reloadableId: "notifications"
  }

  contentComponent: Item {
    id: content

    implicitWidth: Style.bar.audioWidth
    implicitHeight: mainColumn.implicitHeight + root.padding * 2

    ColumnLayout {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: root.padding
      spacing: root.spacing

      IBox {
        id: title

        Layout.fillWidth: true
        implicitHeight: titleRow.implicitHeight + root.padding * 2

        RowLayout {
          id: titleRow
          anchors.fill: parent
          anchors.margins: root.padding
          spacing: spacing

          IText {
            Layout.fillWidth: true
            text: root.notifCount > 0 ? root.notifCount + " notifications" : "Notifications"
            color: ThemeService.palette.mOutline
            font.pointSize: Style.appearance.font.size.normal
            font.family: Settings.appearance.font.mono
          }

          ISwitch {
            checked: !NotificationService.dnd
            onToggled: {
              NotificationService.dnd = !NotificationService.dnd;
            }
          }

          IIconButton {
            icon: "delete"
            size: Style.appearance.widget.size * 0.8
            enabled: root.notifCount > 0
            onClicked: NotificationService.clear()
          }

          IIconButton {
            icon: "close"
            size: Style.appearance.widget.size * 0.8
            onClicked: root.close()
          }
        }
      }

      IBox {
        id: notifBox
        Layout.fillWidth: true
        implicitHeight: root.notifCount > 0 ? Math.min(view.contentHeight + root.padding * 2, 480) : 320

        Loader {
          anchors.centerIn: parent
          asynchronous: true
          active: opacity > 0
          opacity: root.notifCount > 0 ? 0 : 1

          sourceComponent: ColumnLayout {
            spacing: Style.appearance.spacing.large

            Image {
              asynchronous: true
              source: Qt.resolvedUrl(Settings.notifications.background)
              fillMode: Image.PreserveAspectFit
              sourceSize.height: notifBox.height * 0.8

              layer.enabled: true
              layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: ThemeService.palette.mOutline
                brightness: 1

                Behavior on colorizationColor {
                  ICAnim {}
                }
              }
            }

            IText {
              Layout.alignment: Qt.AlignHCenter
              text: "No notifications"
              color: ThemeService.palette.mOutline
              font.pointSize: Style.appearance.font.size.large
              font.family: Settings.appearance.font.mono
              font.weight: 500
            }
          }

          Behavior on opacity {
            IAnim {
              duration: Style.appearance.anim.durations.extraLarge
            }
          }
        }

        IFlickable {
          id: view

          anchors.fill: parent
          anchors.margins: root.padding
          clip: true
          contentWidth: width
          contentHeight: notifList.implicitHeight
          boundsBehavior: Flickable.StopAtBounds

          NotificationList {
            id: notifList
            container: view
            props: props
          }
        }
      }
    }
  }
}
