pragma ComponentBehavior

import QtQuick
import Quickshell.Io
import qs.commons
import "../helpers/sha256.js" as Checksum

Image {
  id: root

  property string imagePath: ""
  property string imageHash: ""
  property string cacheFolder: Directories.shellCacheImagesDir
  property int maxCacheDimension: 512
  readonly property string cachePath: imageHash ? `${cacheFolder}/${imageHash}@${maxCacheDimension}x${maxCacheDimension}.png` : ""

  asynchronous: true
  fillMode: Image.PreserveAspectCrop
  sourceSize.width: maxCacheDimension
  sourceSize.height: maxCacheDimension
  smooth: true
  onImagePathChanged: {
    if (imagePath) {
      imageHash = Checksum.sha256(imagePath);
    } else {
      source = "";
      imageHash = "";
    }
  }
  onCachePathChanged: {
    if (imageHash && cachePath) {
      cacheChecker.command = ["test", "-f", cachePath];
      cacheChecker.running = true;
    }
  }
  onStatusChanged: {
    if (source === cachePath && status === Image.Error) {
      source = imagePath;
    } else if (source === imagePath && status === Image.Ready && imageHash && cachePath) {
      const grabPath = cachePath;
      if (visible && width > 0 && height > 0 && Window.window && Window.window.visible)
        grabToImage(res => {
          return res.saveToFile(grabPath);
        });
    }
  }

  Process {
    id: cacheChecker
    running: false
    onExited: function (exitCode) {
      if (exitCode === 0 && root.cachePath) {
        root.source = root.cachePath;
      } else if (root.imagePath) {
        root.source = root.imagePath;
      }
    }
  }
}
