pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config
import qs.commons
import qs.widgets
import qs.services

Rectangle {
  id: root

  property ShellScreen screen

  property bool drawerEnabled: true
  property var filteredItems: []
  property var dropdownItems: []

  readonly property real iconSize: Math.round(Config.bar.sizes.innerHeight * 0.65)

  Timer {
    id: updateDebounceTimer
    interval: 100
    repeat: false
    onTriggered: root._performFilteredItemsUpdate()
  }

  function _performFilteredItemsUpdate() {
    let newItems = [];
    if (SystemTray.items && SystemTray.items.values) {
      const trayItems = SystemTray.items.values;
      for (let i = 0; i < trayItems.length; i++) {
        const item = trayItems[i];
        if (!item)
          continue;
        const title = item.tooltipTitle || item.name || item.id || "";

        // Blacklist
        let isBlacklisted = false;
        for (let j = 0; j < Settings.tray.blacklist.length; j++) {
          if (wildCardMatch(title, Settings.tray.blacklist[j])) {
            isBlacklisted = true;
            break;
          }
        }
        if (!isBlacklisted)
          newItems.push(item);
      }
    }

    // Drawer logic
    if (!root.drawerEnabled) {
      filteredItems = newItems;
      dropdownItems = [];
      return;
    }

    if (Settings.tray.favorites.length > 0) {
      let fav = [];
      for (let item of newItems) {
        const title = item.tooltipTitle || item.name || item.id || "";
        for (let rule of Settings.tray.favorites) {
          if (wildCardMatch(title, rule)) {
            fav.push(item);
            break;
          }
        }
      }

      filteredItems = fav;

      // Non-fav
      let nonFav = [];
      for (let item of newItems) {
        if (!fav.includes(item))
          nonFav.push(item);
      }
      dropdownItems = nonFav;
    } else {
      filteredItems = [];
      dropdownItems = newItems;
    }
  }

  function updateFilteredItems() {
    updateDebounceTimer.restart();
  }

  function wildCardMatch(str, rule) {
    if (!str || !rule) {
      return false;
    }
    let escapedRule = rule.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    let pattern = escapedRule.replace(/\\\*/g, '.*');
    pattern = '^' + pattern + '$';

    try {
      const regex = new RegExp(pattern, 'i');
      return regex.test(str);
    } catch (e) {
      return false;
    }
  }

  implicitWidth: Math.round(trayFlow.implicitWidth)
  implicitHeight: Config.bar.sizes.innerHeight
  radius: Settings.appearance.cornerRadius
  color: ThemeService.palette.mSurfaceContainer

  Connections {
    target: SystemTray.items
    function onValuesChanged() {
      root.updateFilteredItems();
    }
  }

  Connections {
    target: Settings
    function onSettingsSaved() {
      root.updateFilteredItems();
    }
  }

  Component.onCompleted: root.updateFilteredItems()

  Flow {
    id: trayFlow
    spacing: Config.appearance.spacing.small
    flow: Flow.LeftToRight

    Repeater {
      id: repeater
      model: root.filteredItems

      delegate: Item {
        id: trayItem
        required property var modelData

        width: Config.bar.sizes.innerHeight
        height: Config.bar.sizes.innerHeight

        IconImage {
          id: trayIcon
          width: root.iconSize
          height: root.iconSize
          anchors.centerIn: parent
          asynchronous: true
          backer.fillMode: Image.PreserveAspectFit

          property bool menuJustOpened: false

          source: {
            let icon = trayItem.modelData?.icon || "";
            if (!icon)
              return "";

            if (icon.includes("?path=")) {
              const [name, path] = icon.split("?path=");
              const file = name.substring(name.lastIndexOf("/") + 1);
              return `file://${path}/${file}`;
            }
            return icon;
          }
          opacity: status === Image.Ready ? 1 : 0

          layer.enabled: Settings.tray.colorize
          layer.effect: ShaderEffect {
            property color targetColor: ThemeService.palette.mPrimary
            property real colorizeMode: 1.0
            fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/shaders/qsb/appicon_colorize.frag.qsb")
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onClicked: mouse => {
              if (!trayItem.modelData)
                return;
              const menuPanel = VisibilityService.getPanel("tray-menu", root.screen);

              if (mouse.button === Qt.LeftButton) {
                menuPanel?.close();
                if (!trayItem.modelData.onlyMenu)
                  trayItem.modelData.activate();
              } else if (mouse.button === Qt.MiddleButton) {
                menuPanel?.close();
                trayItem.modelData.secondaryActivate();
              } else if (mouse.button === Qt.RightButton) {
                const panel = menuPanel;
                if (panel?.visible) {
                  panel.close();
                  return;
                }

                if (trayItem.modelData.hasMenu && trayItem.modelData.menu) {
                  if (panel) {
                    panel.menu = trayItem.modelData.menu;
                    panel.trayItem = trayItem.modelData;
                    panel.open(parent);
                    trayIcon.menuJustOpened = true;
                  } else {}
                }
              }
            }

            onEntered: {
              const menuPanel = VisibilityService.getPanel("tray-menu", root.screen);
              if (!trayIcon.menuJustOpened && menuPanel && menuPanel.trayItem !== trayItem.modelData)
                menuPanel.close();
              trayIcon.menuJustOpened = false;
            }
          }
        }
      }
    }

    IIconButton {
      id: chevronIcon
      visible: root.drawerEnabled && root.dropdownItems.length > 0
      icon: "arrow_drop_down"
      colorBg: ThemeService.palette.mSurfaceContainer
      colorBgHover: ThemeService.palette.mSurfaceContainerHigh
      colorFg: ThemeService.palette.mPrimary
      colorFgHover: ThemeService.palette.mPrimary
      radius: Settings.appearance.cornerRadius
      border.width: 0
      onClicked: {
        VisibilityService.getPanel("tray-drawer", root.screen)?.toggle(this);
      }
    }
  }
}
