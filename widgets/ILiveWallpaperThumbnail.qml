pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell.Io
import qs.common
import "../helpers/sha256.js" as Checksum

Item {
  id: root

  property string videoPath: ""
  property bool active: true
  property int maxCacheDimension: 384
  property string cacheFolder: Directories.shellCacheThumbnailDir

  property bool cacheChecked: false
  property bool cacheAvailable: false
  property bool failed: false
  property bool generatorHeld: false

  readonly property string videoHash: videoPath ? Checksum.sha256(videoPath) : ""
  readonly property string cachePath: videoHash ? `${cacheFolder}/${videoHash}@${maxCacheDimension}x${maxCacheDimension}-live.jpg` : ""
  readonly property bool shouldGenerate: active && cacheChecked && !cacheAvailable && !failed && videoPath !== ""
  readonly property bool hasPreview: cachedImage.status === Image.Ready || (generator.item && generator.item.frameReady)

  function mediaUrl(path) {
    if (!path)
      return "";
    if (path.indexOf("://") >= 0)
      return path;
    if (!path.startsWith("/"))
      return path;
    return "file://" + path.split("/").map(segment => encodeURIComponent(segment)).join("/");
  }

  function inspectCache() {
    cacheChecker.running = false;
    cacheChecked = false;
    cacheAvailable = false;
    failed = false;
    generatorHeld = false;
    if (!cachePath)
      return;
    cacheChecker.checkedPath = cachePath;
    cacheChecker.command = ["test", "-f", cachePath];
    cacheChecker.running = true;
  }

  onCachePathChanged: inspectCache()
  Component.onCompleted: {
    if (cachePath && !cacheChecker.running)
      inspectCache();
  }

  Loader {
    id: generator

    anchors.fill: parent
    active: root.shouldGenerate || root.generatorHeld

    sourceComponent: Item {
      id: generatorItem

      property bool frameReady: false

      opacity: frameReady ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: 250
          easing.type: Easing.OutCubic
        }
      }

      VideoOutput {
        id: videoOutput

        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
      }

      MediaPlayer {
        id: player

        activeAudioTrack: -1
        source: root.mediaUrl(root.videoPath)
        videoOutput: videoOutput

        onErrorOccurred: function(error, errorString) {
          console.warn("Live wallpaper thumbnail failed:", root.videoPath, errorString);
          root.failed = true;
        }
      }

      Connections {
        target: videoOutput.videoSink
        enabled: !generatorItem.frameReady

        function onVideoFrameChanged() {
          generatorItem.frameReady = true;
          player.pause();
          captureTimer.start();
        }
      }

      Timer {
        id: captureTimer

        interval: 50
        repeat: false
        onTriggered: generatorItem.captureFrame()
      }

      Component.onCompleted: player.play()
      Component.onDestruction: {
        captureTimer.stop();
        player.stop();
        player.source = "";
      }

      function captureFrame() {
        if (!frameReady || videoOutput.width <= 0 || videoOutput.height <= 0) {
          captureTimer.restart();
          return;
        }

        const capturedPath = root.videoPath;
        const capturedCachePath = root.cachePath;
        const scale = Math.min(1, root.maxCacheDimension / videoOutput.width, root.maxCacheDimension / videoOutput.height);
        const targetSize = Qt.size(Math.max(1, Math.round(videoOutput.width * scale)), Math.max(1, Math.round(videoOutput.height * scale)));
        const accepted = videoOutput.grabToImage(result => {
          if (capturedPath !== root.videoPath || capturedCachePath !== root.cachePath)
            return;
          if (result.saveToFile(capturedCachePath)) {
            root.generatorHeld = true;
            root.cacheAvailable = true;
          } else {
            console.warn("Failed to cache live wallpaper thumbnail:", capturedPath);
            root.failed = true;
          }
          player.stop();
        }, targetSize);

        if (!accepted) {
          console.warn("Failed to capture live wallpaper thumbnail:", capturedPath);
          root.failed = true;
          player.stop();
        }
      }
    }
  }

  Image {
    id: cachedImage

    anchors.fill: parent
    source: root.cacheAvailable ? root.cachePath : ""
    asynchronous: true
    cache: false
    fillMode: Image.PreserveAspectCrop
    smooth: true
    opacity: status === Image.Ready ? 1 : 0

    onStatusChanged: {
      if (status === Image.Ready)
        releaseGenerator.restart();
      else if (status === Image.Error && root.cacheAvailable) {
        root.generatorHeld = false;
        root.failed = true;
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: 250
        easing.type: Easing.OutCubic
      }
    }
  }

  Timer {
    id: releaseGenerator

    interval: 250
    repeat: false
    onTriggered: root.generatorHeld = false
  }

  Process {
    id: cacheChecker

    property string checkedPath: ""
    running: false

    onExited: function(exitCode) {
      if (checkedPath !== root.cachePath)
        return;
      root.cacheAvailable = exitCode === 0;
      root.cacheChecked = true;
    }
  }
}
