pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.commons
import qs.modules.bar

Scope {
  id: root

  required property ShellScreen screen
  required property Bar bar

  ExclusionZone {
    anchors.left: true
  }

  ExclusionZone {
    anchors.top: true
    exclusiveZone: root.bar.exclusiveZone
  }

  ExclusionZone {
    anchors.right: true
  }

  ExclusionZone {
    anchors.bottom: true
  }

  component ExclusionZone: PanelWindow {
    screen: root.screen
    color: "transparent"
    WlrLayershell.namespace: "quickshell:border-exclusion-" + (root.screen?.name || "unknown")
    exclusiveZone: Settings.appearance.thickness
    mask: Region {}
    implicitWidth: 1
    implicitHeight: 1
  }
}
