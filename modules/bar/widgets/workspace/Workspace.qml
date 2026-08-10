pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets
import qs.utils

ClippingRectangle {
  id: root

  property ShellScreen screen

  property ListModel localWorkspaces: ListModel {}
  property ListModel localWindows: ListModel {}
  property int activeWsIdx: 1
  property int groupOffset: Math.floor((root.activeWsIdx - 1) / Settings.bar.workspace.shown) * Settings.bar.workspace.shown

  property int wheelAccumulatedDelta: 0
  property bool wheelCooldown: false

  implicitHeight: Style.bar.innerHeight
  implicitWidth: layout.implicitWidth + Style.spacing.small * 2

  radius: Style.rounding.small
  color: ThemeService.palette.mSurfaceContainer

  Component.onCompleted: {
    refreshWorkspaces();
  }

  onScreenChanged: refreshWorkspaces()

  Connections {
    target: CompositorService
    function onWorkspaceChanged() {
      root.refreshWorkspaces();
    }
  }

  function refreshWorkspaces() {
    localWorkspaces.clear();
    if (screen !== null) {
      for (let i = 0; i < CompositorService.workspaces.count; i++) {
        const ws = CompositorService.workspaces.get(i);
        if (ws.output.toLowerCase() === screen.name.toLowerCase()) {
          localWorkspaces.append(ws);
        }
      }
    }
    updateWorkspaceFocus();
  }

  function updateWorkspaceFocus() {
    for (let i = 0; i < localWorkspaces.count; i++) {
      const ws = localWorkspaces.get(i);
      if (ws.isFocused === true) {
        activeWsIdx = ws.idx;
        break;
      }
    }
  }

  function switchByOffset(offset) {
    if (localWorkspaces.count === 0)
      return;
    let current = activeWsIdx - 1;
    if (current < 0)
      current = 0;
    let next = (current + offset) % localWorkspaces.count;
    if (next < 0)
      next = localWorkspaces.count - 1;
    const ws = localWorkspaces.get(next);
    if (ws && ws.idx !== undefined)
      CompositorService.switchToWorkspace(ws);
  }

  Timer {
    id: wheelDebounce
    interval: 150
    repeat: false
    onTriggered: {
      root.wheelCooldown = false;
      root.wheelAccumulatedDelta = 0;
    }
  }

  WheelHandler {
    id: wheelHandler
    target: root
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function (event) {
      if (root.wheelCooldown)
        return;

      const dy = event.angleDelta.y;
      const dx = event.angleDelta.x;
      const useDy = Math.abs(dy) >= Math.abs(dx);
      const delta = useDy ? dy : dx;

      root.wheelAccumulatedDelta += delta;
      const step = 120;
      if (Math.abs(root.wheelAccumulatedDelta) >= step) {
        const direction = root.wheelAccumulatedDelta > 0 ? -1 : 1;
        root.switchByOffset(direction);
        root.wheelCooldown = true;
        wheelDebounce.restart();
        root.wheelAccumulatedDelta = 0;
        event.accepted = true;
      }
    }
  }

  Item {
    anchors.fill: parent

    RowLayout {
      id: layout
      spacing: Style.spacing.small / 2
      anchors.centerIn: parent

      Repeater {
        id: workspaces
        model: Settings.bar.workspace.shown

        WorkspaceItem {
          required property int index

          workspace: {
            const i = root.groupOffset + index;
            return i < root.localWorkspaces.count ? root.localWorkspaces.get(i) : null;
          }
          activeWsIdx: root.activeWsIdx
        }
      }
    }

    Loader {
      anchors.verticalCenter: parent.verticalCenter
      active: Settings.bar.workspace.activeIndicator
      asynchronous: true

      sourceComponent: ActiveIndicator {
        activeWsIdx: root.activeWsIdx
        workspaces: workspaces
        mask: layout
      }
    }
  }
}
