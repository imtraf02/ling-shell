pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  property var registeredPanels: ({})
  property var panelHosts: ({})
  property var openedPanel: null
  property var closingPanel: null
  property bool closedImmediately: false
  property bool isInitializingKeyboard: false

  signal willOpen
  signal didClose

  property var backgroundSlotAssignments: [null, null]
  signal slotAssignmentChanged(int slotIndex, var panel)

  function assignToSlot(slotIndex, panel) {
    if (backgroundSlotAssignments[slotIndex] !== panel) {
      var newAssignments = backgroundSlotAssignments.slice();
      newAssignments[slotIndex] = panel;
      backgroundSlotAssignments = newAssignments;
      slotAssignmentChanged(slotIndex, panel);
    }
  }

  property var popupMenuWindows: ({})
  signal popupMenuWindowRegistered(var screen)

  function registerPanel(panel) {
    registeredPanels[panel.objectName] = panel;
    registeredPanels = Object.assign({}, registeredPanels);
  }

  function unregisterPanel(panel) {
    if (!panel)
      return;
    const next = Object.assign({}, registeredPanels);
    for (const key in next) {
      if (next[key] === panel)
        delete next[key];
    }
    registeredPanels = next;
    if (openedPanel === panel)
      openedPanel = null;
    if (closingPanel === panel)
      closingPanel = null;
    for (let i = 0; i < backgroundSlotAssignments.length; i++) {
      if (backgroundSlotAssignments[i] === panel)
        assignToSlot(i, null);
    }
  }

  function registerPanelHost(screen, host) {
    if (screen && host)
      panelHosts[screen.name] = host;
  }

  function unregisterPanelHost(screen, host) {
    if (!screen || panelHosts[screen.name] !== host)
      return;
    const next = Object.assign({}, panelHosts);
    delete next[screen.name];
    panelHosts = next;
  }

  function registerPopupMenuWindow(screen, window) {
    if (!screen || !window)
      return;
    var key = screen.name;
    popupMenuWindows[key] = window;
    popupMenuWindowRegistered(screen);
  }

  function getPopupMenuWindow(screen) {
    if (!screen)
      return null;
    return popupMenuWindows[screen.name] || null;
  }

  function getPanel(name, screen) {
    if (!screen) {
      for (var key in registeredPanels) {
        if (key.startsWith(name + "-")) {
          return registeredPanels[key];
        }
      }
      return null;
    }

    var panelKey = `${name}-${screen.name}`;

    if (registeredPanels[panelKey]) {
      return registeredPanels[panelKey];
    }

    const host = panelHosts[screen.name];
    return host ? host.ensurePanel(name) : null;
  }

  function hasPanel(name) {
    return name in registeredPanels;
  }

  Timer {
    id: keyboardInitTimer
    interval: 100
    repeat: false
    onTriggered: {
      root.isInitializingKeyboard = false;
    }
  }

  function willOpenPanel(panel) {
    if (openedPanel && openedPanel !== panel) {
      closingPanel = openedPanel;
      assignToSlot(1, closingPanel);
      openedPanel.close();
    }

    openedPanel = panel;
    assignToSlot(0, panel);

    if (panel.exclusiveKeyboard) {
      isInitializingKeyboard = true;
      keyboardInitTimer.restart();
    }

    willOpen();
  }

  function closedPanel(panel) {
    if (openedPanel && openedPanel === panel) {
      openedPanel = null;
      assignToSlot(0, null);
    }

    if (closingPanel && closingPanel === panel) {
      closingPanel = null;
      assignToSlot(1, null);
    }

    isInitializingKeyboard = false;
    keyboardInitTimer.stop();

    didClose();
  }
}
