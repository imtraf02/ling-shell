pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

Scope {
  id: root

  property ShellScreen detectedScreen
  property var pendingCallback: null

  IpcHandler {
    target: "bar"

    function toggle() {
      root.withTargetScreen(screen => {
        BarService.isVisible = !BarService.isVisible;
      });
    }
  }

  IpcHandler {
    target: "launcher"

    function toggle() {
      root.withTargetScreen(screen => {
        PanelService.getPanel("panel:launcher", screen).toggle();
      });
    }
  }

  IpcHandler {
    target: "session"

    function toggle() {
      root.withTargetScreen(screen => {
        PanelService.getPanel("panel:session", screen).toggle();
      });
    }
  }

  IpcHandler {
    target: "media"

    function toggle() {
      root.withTargetScreen(screen => {
        const panel = PanelService.getPanel("panel:media", screen);
        if (panel) {
          panel.toggle();
          return;
        }
        Qt.callLater(() => PanelService.getPanel("panel:media", screen)?.toggle());
      });
    }
  }

  IpcHandler {
    target: "dashboard"

    function toggle() {
      if (!Settings.dashboard.enabled)
        return;
      root.withTargetScreen(screen => {
        const panel = PanelService.getPanel("panel:dashboard", screen);
        if (panel) {
          panel.toggle();
          return;
        }
        Qt.callLater(() => PanelService.getPanel("panel:dashboard", screen)?.toggle());
      });
    }

    function open(tab: string) {
      if (!Settings.dashboard.enabled)
        return;
      DashboardService.select(tab || Settings.dashboard.defaultTab);
      root.withTargetScreen(screen => {
        const panel = PanelService.getPanel("panel:dashboard", screen);
        if (panel) {
          panel.open();
          return;
        }
        Qt.callLater(() => PanelService.getPanel("panel:dashboard", screen)?.open());
      });
    }

    function close() {
      const panel = PanelService.openedPanel;
      if (panel && String(panel.objectName).startsWith("panel:dashboard-"))
        panel.close();
    }
  }

  IpcHandler {
    target: "audio"

    function volume(action: string) {
      switch (action) {
      case "increase":
        AudioService.increaseVolume();
        break;
      case "decrease":
        AudioService.decreaseVolume();
        break;
      case "mute":
        AudioService.setOutputMuted(!AudioService.muted);
        break;
      }
    }

    function mic(action: string) {
      if (action === "mute") {
        AudioService.source.audio.muted = !AudioService.source.audio.muted;
      }
    }
  }

  IpcHandler {
    target: "brightness"

    function increase() {
      root.withTargetScreen(screen => {
        BrightnessService.getMonitorForScreen(screen)?.increaseBrightness();
      });
    }

    function decrease() {
      root.withTargetScreen(screen => {
        BrightnessService.getMonitorForScreen(screen)?.decreaseBrightness();
      });
    }
  }

  // IpcHandler {
  //   target: "notifs"

  //   function clear(): void {
  //     for (const notif of NotificationService.list.slice())
  //       notif.close();
  //   }

  //   function isDndEnabled(): bool {
  //     return NotificationService.dnd;
  //   }

  //   function toggleDnd(): void {
  //     NotificationService.dnd = !NotificationService.dnd;
  //   }

  //   function enableDnd(): void {
  //     NotificationService.dnd = true;
  //   }

  //   function disableDnd(): void {
  //     NotificationService.dnd = false;
  //   }
  // }

  IpcHandler {
    target: "lock"

    function lock() {
      CompositorService.lock();
    }
  }

  function withTargetScreen(callback) {
    if (pendingCallback) {
      return;
    }

    // Single monitor setup can execute immediately
    if (Quickshell.screens.length === 1) {
      callback(Quickshell.screens[0]);
    } else {
      // Multi-monitors setup needs to start async detection
      detectedScreen = null;
      pendingCallback = callback;
      screenDetectorLoader.active = true;
    }
  }

  Timer {
    id: screenDetectorDebounce
    running: false
    interval: 20
    onTriggered: {
      if (root.pendingCallback) {
        root.pendingCallback(root.detectedScreen);
        root.pendingCallback = null;
      }

      // Clean up
      screenDetectorLoader.active = false;
    }
  }

  Loader {
    id: screenDetectorLoader
    active: false

    sourceComponent: PanelWindow {
      implicitWidth: 0
      implicitHeight: 0
      color: "transparent"
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      onScreenChanged: {
        root.detectedScreen = screen;
        screenDetectorDebounce.restart();
      }
    }
  }
}
