pragma Singleton

import Quickshell

Singleton {
  id: root

  property var lock: null
  property bool locked: false
  property bool bar: false
  property bool barIsHovered: false

  property var registeredPanels: ({})
  property var openedPanel: null

  property var openedPopups: []
  property bool hasOpenedPopup: false
  signal popupChanged

  function registerPanel(panel) {
    registeredPanels[panel.objectName] = panel;
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

    const panelKey = `${name}-${screen.name}`;

    if (registeredPanels[panelKey]) {
      return registeredPanels[panelKey];
    }

    return null;
  }

  function closedPanel(panel) {
    if (openedPanel && openedPanel === panel) {
      openedPanel = null;
    }
  }

  function willOpenPanel(panel) {
    if (openedPanel && openedPanel !== panel) {
      openedPanel.close();
    }
    openedPanel = panel;
  }

  // Popups
  function willOpenPopup(popup) {
    openedPopups.push(popup);
    hasOpenedPopup = (openedPopups.length !== 0);
    popupChanged();
  }

  function willClosePopup(popup) {
    openedPopups = openedPopups.filter(p => p !== popup);
    hasOpenedPopup = (openedPopups.length !== 0);
    popupChanged();
  }
}
