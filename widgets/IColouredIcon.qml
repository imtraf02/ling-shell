pragma ComponentBehavior: Bound

import Quickshell.Widgets
import QtQuick

IconImage {
  id: root

  required property color colour

  asynchronous: true

  layer.enabled: true
  layer.effect: IColouriser {
    sourceColor: analyser.dominantColour
    colorizationColor: root.colour
  }

  layer.onEnabledChanged: {
    if (layer.enabled && status === Image.Ready) {
      analyser.requestUpdate();
    }
  }

  onStatusChanged: {
    if (layer.enabled && status === Image.Ready)
      analyser.requestUpdate();
  }

  IImageAnalyser {
    id: analyser

    sourceItem: root
  }
}
