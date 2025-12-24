import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.commons
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

      function setWallpaperInitial() {
        if (!WallpaperService || !WallpaperService.isInitialized) {
          Qt.callLater(setWallpaperInitial);
          return;
        }
        const wallpaperPath = WallpaperService.getWallpaper(modelData.name);
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

      Image {
        id: bgImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: panelWindow.wallpaper
        smooth: true
        mipmap: false
        cache: false
        asynchronous: true
        // Image is heavily blurred, so might as well save a lot of memory here.
        sourceSize: Qt.size(1280, 720)
      }

      MultiEffect {
        anchors.fill: parent
        source: bgImage
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        colorization: 0.5
        colorizationColor: Settings.appearance.theme.mode === "dark" ? ThemeService.palette.mSurface : ThemeService.palette.mOnSurface
      }
    }
  }
}
