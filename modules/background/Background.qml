pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services
import qs.utils

Variants {
  id: backgroundVariants
  model: Quickshell.screens

  delegate: Loader {
    id: loader
    required property ShellScreen modelData

    active: modelData && Settings.wallpaper.enabled

    sourceComponent: PanelWindow {
      id: root

      // Internal state management
      property string transitionType: "fade"
      property real transitionProgress: 0

      readonly property real edgeSmoothness: Settings.wallpaper.transitionEdgeSmoothness
      readonly property bool transitioning: transitionAnimation.running

      // Wipe direction: 0=left, 1=right, 2=up, 3=down
      property real wipeDirection: 0

      // Disc
      property real discCenterX: 0.5
      property real discCenterY: 0.5

      // Stripe
      property real stripesCount: 16
      property real stripesAngle: 0

      // Used to debounce wallpaper changes
      property string futureWallpaper: ""

      // The requested live source can change while the previous video is
      // fading out. loadedLiveSource always describes the MediaPlayer source.
      property string liveSource: ""
      property string loadedLiveSource: ""
      property bool liveFrameReady: false
      property bool frameCapturePending: false
      property int frameCaptureGeneration: 0
      readonly property bool liveFrameNeeded: loadedLiveSource !== "" && LiveWallpaperService.needsFrame(loader.modelData.name, loadedLiveSource)
      readonly property bool playbackAllowed: loadedLiveSource !== "" && (liveFrameNeeded || (!CompositorService.overviewActive && !(CompositorService.lockscreen && CompositorService.lockscreen.locked)))

      // Fillmode default is "crop"
      property real fillMode: Settings.wallpaper.fillMode === "fit" ? Image.PreserveAspectFit : (Settings.wallpaper.fillMode === "stretch" ? Image.Stretch : Image.PreserveAspectCrop)
      property real videoFillMode: Settings.wallpaper.fillMode === "fit" ? VideoOutput.PreserveAspectFit : (Settings.wallpaper.fillMode === "stretch" ? VideoOutput.Stretch : VideoOutput.PreserveAspectCrop)
      property vector4d fillColor: Qt.vector4d(Settings.wallpaper.fillColor.r, Settings.wallpaper.fillColor.g, Settings.wallpaper.fillColor.b, 1.0)

      color: "transparent"
      screen: loader.modelData
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell:wallpaper-" + (screen?.name || "unknown")

      anchors {
        bottom: true
        top: true
        right: true
        left: true
      }

      Timer {
        id: debounceTimer
        interval: 333
        running: false
        repeat: false
        onTriggered: {
          root.changeWallpaper();
        }
      }

      Component.onCompleted: {
        setWallpaperInitial();
        requestLiveSource(LiveWallpaperService.getLiveWallpaper(loader.modelData.name));
      }

      Component.onDestruction: {
        transitionAnimation.stop();
        liveFadeIn.stop();
        liveFadeOut.stop();
        frameCaptureTimer.stop();
        livePlayer.stop();
        livePlayer.source = "";
        debounceTimer.stop();
        shaderLoader.active = false;
        currentWallpaper.source = "";
        nextWallpaper.source = "";
      }

      Connections {
        target: WallpaperService
        function onWallpaperChanged(screenName, path) {
          if (screenName === loader.modelData.name) {
            root.futureWallpaper = path;
            debounceTimer.restart();
          }
        }
      }

      Connections {
        target: LiveWallpaperService
        function onLiveWallpaperChanged(screenName, path) {
          if (screenName === loader.modelData.name)
            root.requestLiveSource(path);
        }
      }

      Connections {
        target: Settings.wallpaper
        function onLiveWallpapersChanged() {
          root.requestLiveSource(LiveWallpaperService.getLiveWallpaper(loader.modelData.name));
        }
      }

      Connections {
        target: CompositorService
        function onDisplayScalesChanged() {
          root.setWallpaperInitial();
        }
      }

      Rectangle {
        anchors.fill: parent
        color: Settings.wallpaper.fillColor
      }

      Image {
        id: currentWallpaper

        property bool dimensionsCalculated: false

        source: ""
        smooth: true
        mipmap: false
        anchors.fill: parent
        fillMode: root.fillMode
        visible: !shaderLoader.active
        cache: false
        asynchronous: true
        sourceSize: undefined
        onStatusChanged: {
          if (status === Image.Error) {
            console.log("Current wallpaper failed to load:", source);
          } else if (status === Image.Ready && !dimensionsCalculated) {
            dimensionsCalculated = true;
            const optimalSize = root.calculateOptimalWallpaperSize(implicitWidth, implicitHeight);
            if (optimalSize !== false) {
              sourceSize = optimalSize;
            }
          }
        }
        onSourceChanged: {
          dimensionsCalculated = false;
          sourceSize = undefined;
        }
      }

      Image {
        id: nextWallpaper

        property bool dimensionsCalculated: false

        source: ""
        smooth: true
        mipmap: false
        visible: false
        cache: false
        asynchronous: true
        sourceSize: undefined
        onStatusChanged: {
          if (status === Image.Error) {} else if (status === Image.Ready && !dimensionsCalculated) {
            dimensionsCalculated = true;
            const optimalSize = root.calculateOptimalWallpaperSize(implicitWidth, implicitHeight);
            if (optimalSize !== false) {
              sourceSize = optimalSize;
            }
          }
        }
        onSourceChanged: {
          dimensionsCalculated = false;
          sourceSize = undefined;
        }
      }

      Loader {
        id: shaderLoader
        anchors.fill: parent
        active: root.transitioning || nextWallpaper.source !== ""
        sourceComponent: ShaderEffect {
          anchors.fill: parent

          property variant source1: currentWallpaper
          property variant source2: nextWallpaper
          property real progress: root.transitionProgress
          property real smoothness: root.edgeSmoothness
          property real aspectRatio: root.width / root.height
          property real stripeCount: root.stripesCount
          property real angle: root.stripesAngle

          // Fill mode properties
          property real fillMode: root.fillMode
          property vector4d fillColor: root.fillColor
          property real imageWidth1: source1.sourceSize.width
          property real imageHeight1: source1.sourceSize.height
          property real imageWidth2: source2.sourceSize.width
          property real imageHeight2: source2.sourceSize.height
          property real screenWidth: width
          property real screenHeight: height

          fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/shaders/qsb/wp_stripes.frag.qsb")
        }
      }

      Item {
        id: liveVideoLayer

        anchors.fill: parent
        opacity: 0

        VideoOutput {
          id: liveVideoOutput

          anchors.fill: parent
          fillMode: root.videoFillMode
        }
      }

      MediaPlayer {
        id: livePlayer

        activeAudioTrack: -1
        loops: MediaPlayer.Infinite
        videoOutput: liveVideoOutput

        onErrorOccurred: function(error, errorString) {
          if (root.loadedLiveSource === "")
            return;
          console.warn("Live wallpaper failed to play:", root.loadedLiveSource, errorString);
          root.liveFrameReady = false;
          liveFadeIn.stop();
          liveFadeOut.restart();
        }
      }

      Connections {
        target: liveVideoOutput.videoSink
        enabled: !root.liveFrameReady || LiveWallpaperService.needsFrame(loader.modelData.name, root.loadedLiveSource)
        function onVideoFrameChanged() {
          root.handleLiveVideoFrame();
        }
      }

      Timer {
        id: frameCaptureTimer

        interval: 50
        repeat: false
        onTriggered: root.captureLiveFrame()
      }

      NumberAnimation {
        id: liveFadeIn

        target: liveVideoLayer
        property: "opacity"
        to: 1
        duration: Math.min(400, Math.max(150, Settings.wallpaper.transitionDuration))
        easing.type: Easing.OutCubic
      }

      NumberAnimation {
        id: liveFadeOut

        target: liveVideoLayer
        property: "opacity"
        to: 0
        duration: 200
        easing.type: Easing.InCubic
        onFinished: {
          if (root.loadedLiveSource !== root.liveSource)
            root.applyLiveSource();
        }
      }

      NumberAnimation {
        id: transitionAnimation
        target: root
        property: "transitionProgress"
        from: 0.0
        to: 1.0
        // The stripes shader feels faster visually, we make it a bit slower here.
        duration: Settings.wallpaper.transitionDuration
        easing.type: Easing.InOutCubic
        onFinished: {
          // Assign new image to current BEFORE clearing to prevent flicker
          const tempSource = nextWallpaper.source;
          currentWallpaper.source = tempSource;
          root.transitionProgress = 0.0;

          // Now clear nextWallpaper after currentWallpaper has the new source
          // Force complete cleanup to free texture memory (~18-25MB per monitor)
          Qt.callLater(() => {
            nextWallpaper.source = "";
            nextWallpaper.sourceSize = undefined;
            Qt.callLater(() => {
              currentWallpaper.asynchronous = true;
            });
          });
        }
      }

      onPlaybackAllowedChanged: updateLivePlayback()

      function mediaUrl(path) {
        if (!path)
          return "";
        if (path.indexOf("://") >= 0)
          return path;
        const normalized = FileUtils.trimFileProtocol(path);
        if (!normalized.startsWith("/"))
          return normalized;
        return "file://" + normalized.split("/").map(segment => encodeURIComponent(segment)).join("/");
      }

      function requestLiveSource(source) {
        const requested = source || "";
        if (requested === liveSource && requested === loadedLiveSource)
          return;
        liveSource = requested;
        frameCaptureTimer.stop();

        if (liveVideoLayer.opacity > 0) {
          liveFadeIn.stop();
          liveFadeOut.restart();
        } else {
          applyLiveSource();
        }
      }

      function applyLiveSource() {
        liveFadeIn.stop();
        liveFadeOut.stop();
        livePlayer.stop();
        livePlayer.source = "";
        liveVideoLayer.opacity = 0;
        liveFrameReady = false;
        frameCaptureGeneration++;
        frameCapturePending = false;
        loadedLiveSource = liveSource;

        if (loadedLiveSource === "")
          return;
        livePlayer.source = mediaUrl(loadedLiveSource);
        updateLivePlayback();
      }

      function updateLivePlayback() {
        if (playbackAllowed) {
          if (livePlayer.playbackState !== MediaPlayer.PlayingState)
            livePlayer.play();
        } else if (livePlayer.playbackState === MediaPlayer.PlayingState) {
          livePlayer.pause();
        }
      }

      function handleLiveVideoFrame() {
        if (loadedLiveSource === "" || loadedLiveSource !== liveSource)
          return;
        if (!liveFrameReady) {
          liveFrameReady = true;
          liveFadeOut.stop();
          liveFadeIn.restart();
          if (LiveWallpaperService.needsFrame(loader.modelData.name, loadedLiveSource))
            livePlayer.pause();
        }
        if (LiveWallpaperService.needsFrame(loader.modelData.name, loadedLiveSource) && !frameCapturePending && !frameCaptureTimer.running)
          frameCaptureTimer.start();
      }

      function captureLiveFrame() {
        if (!liveFrameReady || frameCapturePending || loadedLiveSource === "" || loadedLiveSource !== liveSource)
          return;
        if (!LiveWallpaperService.needsFrame(loader.modelData.name, loadedLiveSource))
          return;
        if (liveVideoOutput.width <= 0 || liveVideoOutput.height <= 0) {
          frameCaptureTimer.restart();
          return;
        }

        const capturedSource = loadedLiveSource;
        const captureGeneration = frameCaptureGeneration;
        const scale = Math.min(1, 960 / liveVideoOutput.width, 540 / liveVideoOutput.height);
        const targetSize = Qt.size(Math.max(1, Math.round(liveVideoOutput.width * scale)), Math.max(1, Math.round(liveVideoOutput.height * scale)));
        frameCapturePending = true;
        const accepted = liveVideoOutput.grabToImage(result => {
          if (captureGeneration !== root.frameCaptureGeneration)
            return;
          root.frameCapturePending = false;
          if (capturedSource !== root.loadedLiveSource || capturedSource !== root.liveSource)
            return;
          if (result.saveToFile(LiveWallpaperService.framePath(loader.modelData.name)))
            LiveWallpaperService.markFrameReady(loader.modelData.name, capturedSource);
          else
            console.warn("Failed to cache live wallpaper frame for", loader.modelData.name);
          root.updateLivePlayback();
        }, targetSize);
        if (!accepted) {
          frameCapturePending = false;
          updateLivePlayback();
        }
      }

      function setWallpaperInitial() {
        // On startup, defer assigning wallpaper until the service cache is ready, retries every tick
        if (!WallpaperService || !WallpaperService.isInitialized) {
          Qt.callLater(setWallpaperInitial);
          return;
        }

        setWallpaperImmediate(WallpaperService.getWallpaper(loader.modelData.name));
      }

      function setWallpaperImmediate(source) {
        transitionAnimation.stop();
        transitionProgress = 0.0;

        // Clear nextWallpaper completely to free texture memory
        nextWallpaper.source = "";
        nextWallpaper.sourceSize = undefined;

        Qt.callLater(() => {
          currentWallpaper.source = source;
        });
      }

      function calculateOptimalWallpaperSize(wpWidth, wpHeight) {
        const compositorScale = CompositorService.getDisplayScale(loader.modelData.name);
        const screenWidth = loader.modelData.width * compositorScale;
        const screenHeight = loader.modelData.height * compositorScale;

        if (wpWidth <= screenWidth || wpHeight <= screenHeight || wpWidth <= 0 || wpHeight <= 0) {
          return;
        }

        const imageAspectRatio = wpWidth / wpHeight;
        var dim = Qt.size(0, 0);
        if (screenWidth >= screenHeight) {
          const w = Math.min(screenWidth, wpWidth);
          dim = Qt.size(w, w / imageAspectRatio);
        } else {
          const h = Math.min(screenHeight, wpHeight);
          dim = Qt.size(h * imageAspectRatio, h);
        }

        return dim;
      }

      function setWallpaperWithTransition(source) {
        if (source === currentWallpaper.source) {
          return;
        }

        if (transitioning) {
          transitionAnimation.stop();
          transitionProgress = 0;

          const newCurrentSource = nextWallpaper.source;
          currentWallpaper.source = newCurrentSource;

          Qt.callLater(() => {
            nextWallpaper.source = "";

            Qt.callLater(() => {
              nextWallpaper.source = source;
              currentWallpaper.asynchronous = false;
              transitionAnimation.start();
            });
          });
          return;
        }

        nextWallpaper.source = source;
        currentWallpaper.asynchronous = false;
        transitionAnimation.start();
      }

      function changeWallpaper() {
        stripesCount = Math.round(Math.random() * 20 + 4);
        stripesAngle = Math.random() * 360;
        setWallpaperWithTransition(futureWallpaper);
      }
    }
  }
}
