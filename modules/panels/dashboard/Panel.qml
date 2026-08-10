pragma ComponentBehavior: Bound

import QtQuick
import qs.common
import qs.modules.panels
import qs.services

SmartPanel {
  id: root

  position: "top"
  anchor: "center"
  animateContentWidth: true

  panelContent: Content {
    screen: root.screen
    panelOpen: root.isPanelOpen
    onCloseRequested: root.close()
    onSettingsRequested: {
      const settingsPanel = PanelService.getPanel("panel:settings", root.screen);
      if (settingsPanel)
        settingsPanel.open();
    }
  }
}
