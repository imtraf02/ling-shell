pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.commons
import qs.modules.bar
import qs.services

Variants {
  model: Quickshell.screens

  Scope {
    id: scope

    required property ShellScreen modelData

    Exclusions {
      screen: scope.modelData
      bar: bar
    }

    PanelWindow {
      id: win

      property bool isPanelOpen: VisibilityService.openedPanel !== null

      WlrLayershell.keyboardFocus: win.isPanelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "quickshell:screen-" + (screen?.name || "unknown")
      WlrLayershell.exclusionMode: ExclusionMode.Ignore

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      color: {
        if (isPanelOpen) {
          return Qt.alpha(ThemeService.palette.mShadow, 0.4);
        }
        return "transparent";
      }

      mask: Region {
        id: clickableMask

        x: Settings.appearance.thickness
        y: bar.implicitHeight
        width: win.width - Settings.appearance.thickness * 2
        height: win.height - Settings.appearance.thickness - bar.implicitHeight
        intersection: Intersection.Xor

        regions: regions.instances.concat([backgroundMaskRegion, notificationsRegion])

        Region {
          id: backgroundMaskRegion
          x: Settings.appearance.thickness
          y: bar.implicitHeight
          width: win.isPanelOpen ? win.width - Settings.appearance.thickness * 2 : 0
          height: win.isPanelOpen ? win.height - Settings.appearance.thickness - bar.implicitHeight : 0
          intersection: Intersection.Subtract
        }

        Region {
          id: notificationsRegion
          x: panels.notificationsPopout.x
          y: panels.notificationsPopout.y
          width: panels.notificationsPopout.width
          height: panels.notificationsPopout.height + Settings.appearance.thickness
          intersection: Intersection.Subtract
        }
      }

      Variants {
        id: regions

        model: panels.children

        Region {
          required property Item modelData

          x: modelData.x
          y: modelData.y
          width: modelData.width
          height: modelData.height
          intersection: Intersection.Subtract
        }
      }

      Item {
        id: container
        anchors.fill: parent

        layer.enabled: true
        layer.effect: MultiEffect {
          shadowEnabled: true
          blurMax: 15
          shadowColor: Qt.alpha(ThemeService.palette.mShadow, 0.8)
        }

        Borders {
          bar: bar
        }

        Backgrounds {
          bar: bar
          panels: panels
        }
      }

      Interactions {
        screen: scope.modelData
        bar: bar
        panels: panels

        Bar {
          id: bar
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right

          screen: scope.modelData
        }

        Panels {
          id: panels
          screen: scope.modelData
          bar: bar
        }
      }
    }
  }
}
