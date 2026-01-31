pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import QtMultimedia
import qs.common
import qs.services

// TODO: Implement LiveBackground.qml
Variants {
  id: backgroundVariants
  model: Quickshell.screens

  delegate: Loader {
    id: loader
    required property ShellScreen modelData

    active: modelData && Settings.wallpaper.enabled

    sourceComponent: PanelWindow {
      id: root

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

      Video {
        anchors.fill: parent
        source: "file:///home/imtraf/Pictures/Wallpapers/moonlit-blade-of-the-white-dragon.mp4"
        autoPlay: true
        loops: MediaPlayer.Infinite
        muted: true
        fillMode: VideoOutput.PreserveAspectCrop
      }
    }
  }
}
