pragma Singleton

import QtQuick
import Quickshell
import qs.commons

Singleton {
  id: root

  readonly property string fontPath: Directories.assetsPath + "/fonts/material-symbols-rounded.ttf"
  readonly property string defaultIcon: "skull"

  // Use synchronous loading at startup
  property FontLoader mainFontLoader: FontLoader {
    id: mainLoader
    source: root.fontPath

    onStatusChanged: {
      if (status === FontLoader.Ready) {
        root.fontReady = true;
      } else if (status === FontLoader.Error) {
        console.error("Icons", "Font failed to load");
      }
    }
  }

  readonly property string fontFamily: mainLoader.name
  property bool fontReady: mainLoader.status === FontLoader.Ready

  signal fontReloaded

  property int fontVersion: 0
  property FontLoader dynamicLoader: null

  Connections {
    target: Quickshell
    function onReloadCompleted() {
      root.reloadFont();
    }
  }

  function reloadFont() {
    fontVersion++;

    if (dynamicLoader) {
      dynamicLoader.destroy();
    }

    dynamicLoader = Qt.createQmlObject(`
            import QtQuick
            FontLoader {
                source: "${root.fontPath}?v=${fontVersion}&t=${Date.now()}"
            }
        `, root, "dynamicFontLoader_" + fontVersion);

    dynamicLoader.statusChanged.connect(function () {
      if (dynamicLoader.status === FontLoader.Ready) {
        mainLoader.source = "";
        mainLoader.source = dynamicLoader.source;
        fontReloaded();
      }
    });
  }
}
