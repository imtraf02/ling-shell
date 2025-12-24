pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Item {
  id: root

  // Sorts floating windows after scrolling ones
  property int floatingWindowPosition: Number.MAX_SAFE_INTEGER

  // Properties that match the facade interface
  property ListModel workspaces: ListModel {}
  property var windows: []
  property int focusedWindowIndex: -1

  property bool overviewActive: false

  // Signals
  signal workspaceChanged
  signal activeWindowChanged
  signal windowListChanged
  signal displayScalesChanged

  // Initialization
  function initialize() {
    niriEventStream.running = true;
    updateWorkspaces();
    updateWindows();
    queryDisplayScales();
  }

  // Update workspaces
  function updateWorkspaces() {
    niriWorkspaceProcess.running = true;
  }

  // Update windows
  function updateWindows() {
    niriWindowsProcess.running = true;
  }

  // Query display scales
  function queryDisplayScales() {
    niriOutputsProcess.running = true;
  }

  // Niri outputs process
  Process {
    id: niriOutputsProcess
    running: false
    command: ["niri", "msg", "--json", "outputs"]

    stdout: SplitParser {
      onRead: function (line) {
        try {
          const outputsData = JSON.parse(line);
          const scales = {};

          for (const outputName in outputsData) {
            const output = outputsData[outputName];
            if (output && output.name) {
              const logical = output.logical || {};
              const currentModeIdx = output.current_mode || 0;
              const modes = output.modes || [];
              const currentMode = modes[currentModeIdx] || {};

              scales[output.name] = {
                "name": output.name,
                "scale": logical.scale || 1.0,
                "width": logical.width || 0,
                "height": logical.height || 0,
                "x": logical.x || 0,
                "y": logical.y || 0,
                "physical_width": (output.physical_size && output.physical_size[0]) || 0,
                "physical_height": (output.physical_size && output.physical_size[1]) || 0,
                "refresh_rate": currentMode.refresh_rate || 0,
                "vrr_supported": output.vrr_supported || false,
                "vrr_enabled": output.vrr_enabled || false,
                "transform": logical.transform || "Normal"
              };
            }
          }

          if (CompositorService && CompositorService.onDisplayScalesUpdated) {
            CompositorService.onDisplayScalesUpdated(scales);
          }
        } catch (e) {}
      }
    }
  }

  // Niri workspace process
  Process {
    id: niriWorkspaceProcess
    running: false
    command: ["niri", "msg", "--json", "workspaces"]

    stdout: SplitParser {
      onRead: function (line) {
        try {
          const workspacesData = JSON.parse(line);
          const workspacesList = [];

          for (const ws of workspacesData) {
            workspacesList.push({
              "id": ws.id,
              "idx": ws.idx,
              "name": ws.name || "",
              "output": ws.output || "",
              "isFocused": ws.is_focused === true,
              "isActive": ws.is_active === true,
              "isUrgent": ws.is_urgent === true,
              "isOccupied": ws.active_window_id ? true : false
            });
          }

          workspacesList.sort((a, b) => {
            if (a.output !== b.output) {
              return a.output.localeCompare(b.output);
            }
            return a.idx - b.idx;
          });

          root.workspaces.clear();
          for (var i = 0; i < workspacesList.length; i++) {
            root.workspaces.append(workspacesList[i]);
          }

          root.workspaceChanged();
        } catch (e) {}
      }
    }
  }

  // Niri windows process
  Process {
    id: niriWindowsProcess
    running: false
    command: ["niri", "msg", "--json", "windows"]

    stdout: SplitParser {
      onRead: function (line) {
        try {
          const windowsData = JSON.parse(line);
          root.recollectWindows(windowsData);
        } catch (e) {}
      }
    }
  }

  // Niri event stream
  Process {
    id: niriEventStream
    running: false
    command: ["niri", "msg", "--json", "event-stream"]

    stdout: SplitParser {
      onRead: data => {
        try {
          const event = JSON.parse(data.trim());

          if (event.WorkspacesChanged) {
            root.updateWorkspaces();
          } else if (event.WindowOpenedOrChanged) {
            root.handleWindowOpenedOrChanged(event.WindowOpenedOrChanged);
          } else if (event.WindowClosed) {
            root.handleWindowClosed(event.WindowClosed);
          } else if (event.WindowsChanged) {
            root.handleWindowsChanged(event.WindowsChanged);
          } else if (event.WorkspaceActivated) {
            root.updateWorkspaces();
          } else if (event.WindowFocusChanged) {
            root.handleWindowFocusChanged(event.WindowFocusChanged);
          } else if (event.WindowLayoutsChanged) {
            root.handleWindowLayoutsChanged(event.WindowLayoutsChanged);
          } else if (event.OverviewOpenedOrClosed) {
            root.handleOverviewOpenedOrClosed(event.OverviewOpenedOrClosed);
          } else if (event.OutputsChanged) {
            root.queryDisplayScales();
          } else if (event.ConfigLoaded) {
            root.queryDisplayScales();
          }
        } catch (e) {}
      }
    }
  }

  // Utilities
  function getWindowPosition(layout) {
    if (layout.pos_in_scrolling_layout) {
      return {
        "x": layout.pos_in_scrolling_layout[0],
        "y": layout.pos_in_scrolling_layout[1]
      };
    } else {
      return {
        "x": floatingWindowPosition,
        "y": floatingWindowPosition
      };
    }
  }

  function getWindowOutput(win) {
    for (var i = 0; i < workspaces.count; i++) {
      if (workspaces.get(i).id === win.workspace_id) {
        return workspaces.get(i).output;
      }
    }
    return null;
  }

  function getWindowData(win) {
    return {
      "id": win.id,
      "title": win.title || "",
      "appId": win.app_id || "",
      "workspaceId": win.workspace_id || -1,
      "isFocused": win.is_focused === true,
      "output": getWindowOutput(win) || "",
      "position": getWindowPosition(win.layout)
    };
  }

  function compareWindows(a, b) {
    if (a.workspaceId !== b.workspaceId) {
      return a.workspaceId - b.workspaceId;
    }
    if (a.position.x !== b.position.x) {
      return a.position.x - b.position.x;
    }
    return a.position.y - b.position.y;
  }

  function recollectWindows(windowsData) {
    const windowsList = [];

    for (const win of windowsData) {
      windowsList.push(getWindowData(win));
    }

    windowsList.sort(compareWindows);
    windows = windowsList;
    windowListChanged();

    focusedWindowIndex = -1;
    for (var i = 0; i < windowsList.length; i++) {
      if (windowsList[i].isFocused) {
        focusedWindowIndex = i;
        break;
      }
    }

    activeWindowChanged();
  }

  // Event handlers
  function handleWindowOpenedOrChanged(eventData) {
    try {
      const windowData = eventData.window;
      const existingIndex = windows.findIndex(w => w.id === windowData.id);
      const newWindow = getWindowData(windowData);

      if (existingIndex >= 0) {
        windows[existingIndex] = newWindow;
      } else {
        windows.push(newWindow);
      }

      windows.sort(compareWindows);

      if (newWindow.isFocused) {
        const oldFocusedIndex = focusedWindowIndex;
        focusedWindowIndex = windows.findIndex(w => w.id === windowData.id);

        if (oldFocusedIndex !== focusedWindowIndex) {
          if (oldFocusedIndex >= 0 && oldFocusedIndex < windows.length) {
            windows[oldFocusedIndex].isFocused = false;
          }
          activeWindowChanged();
        }
      }

      windowListChanged();
    } catch (e) {}
  }

  function handleWindowClosed(eventData) {
    try {
      const windowId = eventData.id;
      const windowIndex = windows.findIndex(w => w.id === windowId);

      if (windowIndex >= 0) {
        if (windowIndex === focusedWindowIndex) {
          focusedWindowIndex = -1;
          activeWindowChanged();
        } else if (focusedWindowIndex > windowIndex) {
          focusedWindowIndex--;
        }

        windows.splice(windowIndex, 1);
        windowListChanged();
      }
    } catch (e) {}
  }

  function handleWindowsChanged(eventData) {
    try {
      const windowsData = eventData.windows;
      recollectWindows(windowsData);
    } catch (e) {}
  }

  function handleWindowFocusChanged(eventData) {
    try {
      const focusedId = eventData.id;

      if (windows[focusedWindowIndex]) {
        windows[focusedWindowIndex].isFocused = false;
      }

      if (focusedId) {
        const newIndex = windows.findIndex(w => w.id === focusedId);

        if (newIndex >= 0 && newIndex < windows.length) {
          windows[newIndex].isFocused = true;
        }

        focusedWindowIndex = newIndex >= 0 ? newIndex : -1;
      } else {
        focusedWindowIndex = -1;
      }

      activeWindowChanged();
    } catch (e) {}
  }

  function handleWindowLayoutsChanged(eventData) {
    try {
      for (const change of eventData.changes) {
        const windowId = change[0];
        const layout = change[1];
        const window = windows.find(w => w.id === windowId);

        if (window) {
          window.position = getWindowPosition(layout);
        }
      }

      windows.sort(compareWindows);
      windowListChanged();
    } catch (e) {}
  }

  function handleOverviewOpenedOrClosed(eventData) {
    try {
      overviewActive = eventData.is_open;
    } catch (e) {}
  }

  // Public APIs
  function switchToWorkspace(workspace) {
    try {
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", workspace.idx.toString()]);
    } catch (e) {}
  }

  function focusWindow(window) {
    try {
      Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", window.id.toString()]);
    } catch (e) {}
  }

  function closeWindow(window) {
    try {
      Quickshell.execDetached(["niri", "msg", "action", "close-window", "--id", window.id.toString()]);
    } catch (e) {}
  }

  function logout() {
    try {
      Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"]);
    } catch (e) {}
  }
}
