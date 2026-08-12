pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.common
import qs.widgets
import qs.services
import qs.modules.panels

SmartPanel {
  id: root

  animateContentHeight: false

  readonly property int notifCount: NotificationService.list.reduce((acc, n) => n.closed ? acc : acc + 1, 0)

  PersistentProperties {
    id: props
    property list<string> expandedNotifs: []

    reloadableId: "notifications"
  }

  panelContent: Item {
    id: content

    readonly property real contentPreferredWidth: Style.bar.notificationsWidth
    readonly property real contentPreferredHeight: mainColumn.implicitHeight + Style.padding.small * 2

    ColumnLayout {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: Style.padding.small
      spacing: Style.spacing.small

      IBox {
        id: title

        Layout.fillWidth: true
        implicitHeight: titleRow.implicitHeight + Style.padding.small * 2

        RowLayout {
          id: titleRow
          anchors.fill: parent
          anchors.margins: Style.padding.small
          spacing: spacing

          IText {
            Layout.fillWidth: true
            text: root.notifCount > 0 ? root.notifCount + " notifications" : "Notifications"
            color: ThemeService.palette.mOutline
            font.pointSize: Style.font.size.normal
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
            size: Style.widget.size * 0.8
            enabled: root.notifCount > 0
            onClicked: NotificationService.clear()
          }

          IIconButton {
            icon: "close"
            size: Style.widget.size * 0.8
            onClicked: root.close()
          }
        }
      }

      IBox {
        id: notifBox
        Layout.fillWidth: true
        implicitHeight: root.notifCount > 0 ? Math.min(view.contentHeight + Style.padding.small * 2, 480) : 320

        Loader {
          anchors.centerIn: parent
          asynchronous: true
          active: opacity > 0
          opacity: root.notifCount > 0 ? 0 : 1

          sourceComponent: ColumnLayout {
            spacing: Style.spacing.large

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
              font.weight: Font.Medium
            }
          }

          Behavior on opacity {
            IAnim {
              duration: Style.anim.durations.extraLarge
            }
          }
        }

        IFlickable {
          id: view

          function clampContentPosition(): void {
            const maxContentY = Math.max(0, contentHeight - height);
            contentY = Math.max(0, Math.min(contentY, maxContentY));
          }

          anchors.fill: parent
          anchors.margins: Style.padding.small
          clip: true
          contentWidth: width
          contentHeight: notifList.implicitHeight
          boundsBehavior: Flickable.StopAtBounds

          onContentHeightChanged: Qt.callLater(clampContentPosition)
          onHeightChanged: Qt.callLater(clampContentPosition)

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
