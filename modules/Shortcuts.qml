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
        VisibilityService.bar = !VisibilityService.bar;
      });
    }
  }

  IpcHandler {
    target: "launcher"

    function toggle() {
      root.withTargetScreen(screen => {
        VisibilityService.getPanel("launcher", screen).toggle();
      });
    }
  }

  IpcHandler {
    target: "session"

    function toggle() {
      root.withTargetScreen(screen => {
        VisibilityService.getPanel("session", screen).toggle();
      });
    }
  }

  IpcHandler {
    target: "audio"

    function volume(action: string) {
      if (["raise", "increase"].includes(action)) {
        AudioService.increaseVolume();
      } else if (["lower", "decrease"].includes(action)) {
        AudioService.decreaseVolume();
      } else if (["mute", "toggle"].includes(action)) {
        AudioService.setOutputMuted(!AudioService.muted);
      }
    }

    function mic(action: string) {
      if (["mute", "toggle"].includes(action)) {
        AudioService.source.audio.muted = !AudioService.source.audio.muted;
      }
    }
  }

  IpcHandler {
    target: "notifs"

    function clear(): void {
      for (const notif of NotificationService.list.slice())
        notif.close();
    }

    function isDndEnabled(): bool {
      return NotificationService.dnd;
    }

    function toggleDnd(): void {
      NotificationService.dnd = !NotificationService.dnd;
    }

    function enableDnd(): void {
      NotificationService.dnd = true;
    }

    function disableDnd(): void {
      NotificationService.dnd = false;
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
