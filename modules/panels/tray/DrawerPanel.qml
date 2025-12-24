pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import qs.config
import qs.commons
import qs.services
import qs.widgets
import ".."

BarPanel {
  id: root

  readonly property var trayValuesAll: (SystemTray.items && SystemTray.items.values) ? SystemTray.items.values : []
  readonly property var trayValues: trayValuesAll.filter(function (it) {
    return !root.isFavorite(it);
  })
  readonly property int itemCount: trayValues.length
  readonly property int maxColumns: 8
  readonly property real cellSize: Math.round(Config.bar.sizes.innerHeight * 0.65)
  readonly property real padding: Config.appearance.padding.normal
  readonly property real spacing: Config.appearance.spacing.small
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
    if (!Settings.tray.favorites || Settings.tray.favorites.length === 0)
      return false;
    const title = item?.tooltipTitle || item?.name || item?.id || "";
    for (var i = 0; i < Settings.tray.favorites.length; i++) {
      if (wildCardMatch(title, Settings.tray.favorites[i]))
        return true;
    }
    return false;
  }

  contentComponent: Item {
    id: content

    implicitWidth: (root.columns * root.cellSize) + ((root.columns - 1) * root.spacing) + (2 * root.padding)
    implicitHeight: (root.rows * root.cellSize) + ((root.rows - 1) * root.spacing) + (2 * root.padding)

    Grid {
      id: grid
      anchors.fill: parent
      anchors.margins: root.padding
      spacing: root.spacing
      columns: root.columns
      rowSpacing: root.spacing
      columnSpacing: root.spacing
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
            layer.enabled: Settings.tray.colorize

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

              onClicked: mouse => {
                if (!trayItem.modelData)
                  return;
                if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu && trayItem.modelData.menu) {
                  const panel = VisibilityService.getPanel("tray-menu", root.screen);
                  if (panel) {
                    panel.menu = trayItem.modelData.menu;
                    panel.trayItem = trayItem.modelData;
                    panel.open(trayIcon);
                  }
                } else if (mouse.button === Qt.LeftButton) {
                  trayItem.modelData.activate();
                  VisibilityService.getPanel("tray-drawer", root.screen)?.close();
                } else if (mouse.button === Qt.MiddleButton) {
                  trayItem.modelData.secondaryActivate();
                  VisibilityService.getPanel("tray-drawer", root.screen)?.close();
                }
              }
            }
          }
        }
      }
    }
  }
}
