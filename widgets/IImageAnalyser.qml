pragma ComponentBehavior: Bound

import QtQuick

Item {
  id: root

  required property var sourceItem

  readonly property color dominantColour: Qt.rgba(colorData.r / 255, colorData.g / 255, colorData.b / 255, 1.0)

  property bool autoUpdate: false
  property int sampleSize: 16

  QtObject {
    id: colorData
    property real r: 128
    property real g: 128
    property real b: 128
  }

  function requestUpdate() {
    if (sourceItem && sourceItem.status === Image.Ready) {
      grabTimer.restart();
    }
  }

  Timer {
    id: grabTimer
    interval: 16
    onTriggered: {
      if (root.sourceItem && root.sourceItem.status === Image.Ready) {
        root.sourceItem.grabToImage(function (result) {
          if (result.image) {
            root.analyzeImage(result.image);
          }
        }, Qt.size(root.sampleSize, root.sampleSize));
      }
    }
  }

  function analyzeImage(image) {
    let r = 0, g = 0, b = 0;
    let pixelCount = 0;

    // Sample the center region for more accurate color detection
    const width = image.width;
    const height = image.height;
    const startX = Math.floor(width * 0.25);
    const startY = Math.floor(height * 0.25);
    const endX = Math.floor(width * 0.75);
    const endY = Math.floor(height * 0.75);

    for (let y = startY; y < endY; y++) {
      for (let x = startX; x < endX; x++) {
        const pixel = image.pixel(x, y);
        const alpha = ((pixel >> 24) & 0xff) / 255;

        // Skip transparent pixels
        if (alpha > 0.1) {
          const pr = (pixel >> 16) & 0xff;
          const pg = (pixel >> 8) & 0xff;
          const pb = pixel & 0xff;

          // Weight by alpha
          r += pr * alpha;
          g += pg * alpha;
          b += pb * alpha;
          pixelCount += alpha;
        }
      }
    }

    if (pixelCount > 0) {
      colorData.r = Math.round(r / pixelCount);
      colorData.g = Math.round(g / pixelCount);
      colorData.b = Math.round(b / pixelCount);
    }
  }

  Connections {
    target: root.sourceItem
    enabled: root.autoUpdate

    function onStatusChanged() {
      if (root.sourceItem.status === Image.Ready) {
        root.requestUpdate();
      }
    }
  }

  Component.onCompleted: {
    if (autoUpdate && sourceItem && sourceItem.status === Image.Ready) {
      requestUpdate();
    }
  }
}
