import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

Loader {
  active: CompositorService.isNiri && Settings.wallpaper.enabled && Settings.wallpaper.overviewEnabled

  sourceComponent: Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      id: panelWindow

      required property ShellScreen modelData
      property string wallpaper: ""

      Component.onCompleted: {
        setWallpaperInitial();
      }

      // External state management
      Connections {
        target: WallpaperService
        function onWallpaperChanged(screenName, path) {
          if (screenName === panelWindow.modelData.name) {
            panelWindow.wallpaper = path;
          }
        }
      }

      Connections {
        target: LiveWallpaperService
        function onFrameChanged(screenName, path) {
          if (screenName === panelWindow.modelData.name)
            panelWindow.wallpaper = path || WallpaperService.getWallpaper(screenName);
        }
        function onLiveWallpaperChanged(screenName) {
          if (screenName === panelWindow.modelData.name)
            panelWindow.setWallpaperInitial();
        }
      }

      function setWallpaperInitial() {
        if (!WallpaperService || !WallpaperService.isInitialized) {
          Qt.callLater(setWallpaperInitial);
          return;
        }
        const wallpaperPath = LiveWallpaperService.hasFrame(modelData.name) ? LiveWallpaperService.framePath(modelData.name) : WallpaperService.getWallpaper(modelData.name);
        if (wallpaperPath && wallpaperPath !== wallpaper) {
          wallpaper = wallpaperPath;
        }
      }

      color: "transparent"
      screen: modelData
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell:overview-" + (screen?.name || "unknown")

      anchors {
        top: true
        bottom: true
        right: true
        left: true
      }

      Loader {
        anchors.fill: parent
        active: CompositorService.overviewActive

        sourceComponent: Item {
          Image {
            id: bgImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: panelWindow.wallpaper
            smooth: true
            mipmap: false
            cache: false
            asynchronous: true
            sourceSize: Qt.size(960, 540)
          }

          MultiEffect {
            anchors.fill: parent
            source: bgImage
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1.0
            blurMax: 32
            colorization: 0.5
            colorizationColor: Settings.appearance.theme.mode === "dark" ? ThemeService.palette.mSurface : ThemeService.palette.mOnSurface
          }
        }
      }
    }
  }
}
