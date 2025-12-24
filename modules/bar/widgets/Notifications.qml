import QtQuick
import Quickshell
import qs.services
import "../extras"

Item {
  id: root

  property ShellScreen screen
  readonly property int notifCount: NotificationService.list.reduce((acc, n) => n.closed ? acc : acc + 1, 0)

  implicitWidth: pill.width
  implicitHeight: pill.height

  BarPill {
    id: pill
    icon: "notifications"
    text: root.notifCount.toString()

    onClicked: {
      VisibilityService.getPanel("notifications", root.screen)?.toggle(this);
    }
  }
}
