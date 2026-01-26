pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import qs.common
import qs.widgets
import qs.services
import qs.modules.panels

SmartPanel {
  id: root

  readonly property var trayValuesAll: (SystemTray.items && SystemTray.items.values) ? SystemTray.items.values : []
  readonly property var trayValues: trayValuesAll.filter(function (it) {
    return !root.isFavorite(it);
  })
  readonly property int itemCount: trayValues.length
  readonly property int maxColumns: 8
  readonly property real cellSize: Math.round(Style.bar.innerHeight * 0.65)
  readonly property int columns: Math.max(1, Math.min(maxColumns, itemCount))
  readonly property int rows: Math.max(1, Math.ceil(itemCount / Math.max(1, columns)))

  function wildCardMatch(str, rule) {
    if (!str || !rule)
      return false;
    let escaped = rule.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    let pattern = '^' + escaped.replace(/\\\*/g, '.*') + '$';
    try {
      return new RegExp(pattern, 'i').test(str);
    } catch (e) {
      return false;
    }
  }

  function isFavorite(item) {
    if (!Settings.bar.tray.favorites || Settings.bar.tray.favorites.length === 0)
      return false;
    const title = item?.tooltipTitle || item?.name || item?.id || "";
    for (let i = 0; i < Settings.bar.tray.favorites.length; i++) {
      if (wildCardMatch(title, Settings.bar.tray.favorites[i]))
        return true;
    }
    return false;
  }

  panelContent: Item {
    id: panelContent

    property real contentPreferredWidth: (root.columns * root.cellSize) + ((root.columns - 1) * Style.padding.small) + (2 * Style.padding.small)
    property real contentPreferredHeight: (root.rows * root.cellSize) + ((root.rows - 1) * Style.padding.small) + (2 * Style.padding.small)

    Grid {
      id: grid
      anchors.fill: parent
      anchors.margins: Style.padding.small
      spacing: Style.spacing.small
      columns: root.columns
      rowSpacing: Style.spacing.small
      columnSpacing: Style.spacing.small
      Repeater {
        id: repeater
        model: root.trayValues

        delegate: Item {
          id: trayItem
          required property var modelData

          width: root.cellSize
          height: root.cellSize

          IColouredIcon {
            id: trayIcon
            anchors.fill: parent
            asynchronous: true
            backer.fillMode: Image.PreserveAspectFit
            source: {
              let icon = trayItem.modelData?.icon || "";
              if (!icon)
                return "";
              if (icon.includes("?path=")) {
                const chunks = icon.split("?path=");
                const name = chunks[0];
                const path = chunks[1];
                const fileName = name.substring(name.lastIndexOf("/") + 1);
                return `file://${path}/${fileName}`;
              }
              return icon;
            }

            colour: ThemeService.palette.mPrimary
            layer.enabled: Settings.bar.tray.colorize

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

              onClicked: mouse => {
                if (!trayItem.modelData)
                  return;
                if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu && trayItem.modelData.menu) {
                  const panel = PanelService.getPanel("panel:tray-menu", root.screen);
                  if (panel) {
                    panel.menu = trayItem.modelData.menu;
                    panel.trayItem = trayItem.modelData;
                    panel.open(this);
                  }
                } else if (mouse.button === Qt.LeftButton) {
                  trayItem.modelData.activate();
                  PanelService.getPanel("panel:tray-drawer", root.screen).close();
                } else if (mouse.button === Qt.MiddleButton) {
                  trayItem.modelData.secondaryActivate();
                  PanelService.getPanel("panel:tray-drawer", root.screen).close();
                }
              }
            }
          }
        }
      }
    }
  }
}
