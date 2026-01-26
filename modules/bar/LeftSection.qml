pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.modules.bar.widgets
import qs.modules.bar.widgets.workspace

RowLayout {
  id: root

  property ShellScreen screen

  spacing: Style.spacing.small

  OsIcon {
    screen: root.screen
  }

  Workspace {
    screen: root.screen
  }

  Media {
    screen: root.screen
  }
}
