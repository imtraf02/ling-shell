import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services
import qs.modules.bar
import qs.modules.drawers

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

      property bool isPanelOpen: (PanelService.openedPanel !== null) && (PanelService.openedPanel.screen === screen)

      WlrLayershell.keyboardFocus: win.isPanelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "quickshell:screen-" + (screen?.name || "unknown")
      WlrLayershell.exclusionMode: ExclusionMode.Ignore

      screen: scope.modelData

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      color: isPanelOpen ? Qt.alpha(ThemeService.palette.mShadow, 0.4) : "transparent"

      mask: Region {
        id: clickableMask

        x: Settings.appearance.thickness
        y: bar.implicitHeight
        width: win.width - Settings.appearance.thickness * 2
        height: win.height - Settings.appearance.thickness - bar.implicitHeight
        intersection: Intersection.Xor

        regions: [backgroundMaskRegion, notificationsRegion]

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
          x: panels.x + panels.notificationsPopout.x
          y: panels.y + panels.notificationsPopout.y
          width: panels.notificationsPopout.width
          height: panels.notificationsPopout.height
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
          shadowColor: ThemeService.palette.mShadow
        }

        Borders {
          bar: bar
        }

        Backgrounds {
          bar: bar
          screen: scope.modelData
          panels: panels
        }
      }

      Interactions {
        screen: scope.modelData
        bar: bar
        isPanelOpen: win.isPanelOpen

        Panels {
          id: panels
          screen: scope.modelData
          bar: bar
        }

        Bar {
          id: bar
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right

          screen: scope.modelData
        }
      }
    }
  }
}
