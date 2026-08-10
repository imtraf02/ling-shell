pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.services

Singleton {
  id: root

  readonly property bool isNiri: true

  property var lockscreen: null

  readonly property alias workspaces: niri.workspaces
  readonly property alias windows: niri.windows
  readonly property alias windowsByWorkspace: niri.windowsByWorkspace
  readonly property alias focusedWindowIndex: niri.focusedWindowIndex
  readonly property alias overviewActive: niri.overviewActive

  property alias displayScales: displayCacheAdapter.displays
  property bool displayScalesLoaded: false

  property string displayCachePath: Directories.shellDisplayCachePath

  signal workspaceChanged
  signal activeWindowChanged
  signal windowListChanged

  Component.onCompleted: niri.initialize()

  FileView {
    id: displayCacheFileView
    path: root.displayCachePath
    printErrors: false
    watchChanges: false
    onLoaded: {
      root.displayScalesLoaded = true;
    }
    onLoadFailed: {
      root.displayScalesLoaded = true;
    }
    onAdapterUpdated: {
      writeAdapter();
    }

    JsonAdapter {
      id: displayCacheAdapter
      property var displays: ({})
    }
  }

  function onDisplayScalesUpdated(scales) {
    displayScales = scales;
    displayScalesChanged();
  }

  function getDisplayScale(displayName) {
    if (!displayName || !displayScales[displayName]) {
      return 1.0;
    }
    return displayScales[displayName].scale || 1.0;
  }

  function getActiveWorkspaceId(outputName) {
    if (!outputName)
      return -1;
    const target = outputName.toLowerCase();

    for (let i = 0; i < workspaces.count; i++) {
      const ws = workspaces.get(i);
      if (ws.output.toLowerCase() === target && ws.isActive) {
        return ws.id;
      }
    }
    return -1;
  }

  NiriService {
    id: niri

    onWorkspaceChanged: root.workspaceChanged()
    onActiveWindowChanged: root.activeWindowChanged()
    onWindowListChanged: root.windowListChanged()
  }

  function switchToWorkspace(workspace) {
    niri.switchToWorkspace(workspace);
  }

  function logout() {
    niri.logout();
  }

  function focusWindow(window) {
    niri.focusWindow(window);
  }

  function closeWindow(window) {
    niri.closeWindow(window);
  }

  function shutdown() {
    Quickshell.execDetached(["sh", "-c", "systemctl poweroff || loginctl poweroff"]);
  }

  function reboot() {
    Quickshell.execDetached(["sh", "-c", "systemctl reboot || loginctl reboot"]);
  }

  function suspend() {
    Quickshell.execDetached(["sh", "-c", "systemctl suspend || loginctl suspend"]);
  }

  function lock() {
    try {
      if (root.lockscreen) {
        root.lockscreen.locked = true;
      }
    } catch (e) {}
  }

  function lockAndSuspend() {
    try {
      if (root.lockscreen) {
        root.lockscreen.locked = true;
      }
    } catch (e) {}
    Qt.callLater(suspend);
  }
}
