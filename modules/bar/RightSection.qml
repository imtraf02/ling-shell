pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.modules.bar.widgets

RowLayout {
  id: root
  property ShellScreen screen

  spacing: Style.spacing.small

  Tray {
    screen: root.screen
  }

  Notifications {
    screen: root.screen
  }

  Volume {
    screen: root.screen
  }

  Brightness {
    screen: root.screen
  }

  Network {
    screen: root.screen
  }

  Battery {
    screen: root.screen
  }
}
