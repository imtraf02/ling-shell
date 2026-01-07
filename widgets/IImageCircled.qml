pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.commons

Rectangle {
  id: root

  property string imagePath: ""
  property color borderColor: "transparent"
  property real borderWidth: 0
  property string fallbackIcon: ""
  property real fallbackIconSize: Style.appearance.font.size.extraLarge

  color: "transparent"
  radius: parent.width * 0.5
  anchors.margins: Style.appearance.padding.small

  Rectangle {
    color: "transparent"
    anchors.fill: parent

    Image {
      id: img
      anchors.fill: parent
      source: root.imagePath
      visible: false // Hide since we're using it as shader source
      mipmap: true
      smooth: true
      asynchronous: true
      antialiasing: true
      fillMode: Image.PreserveAspectCrop
    }

    ShaderEffect {
      anchors.fill: parent

      property var source: ShaderEffectSource {
        sourceItem: img
        hideSource: true
        live: true
        recursive: false
        format: ShaderEffectSource.RGBA
      }

      property real imageOpacity: root.opacity
      fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/shaders/qsb/circled_image.frag.qsb")
      supportsAtlasTextures: false
      blending: true
    }

    // Fallback icon
    Loader {
      active: root.fallbackIcon !== undefined && root.fallbackIcon !== "" && (root.imagePath === undefined || root.imagePath === "")
      anchors.centerIn: parent
      sourceComponent: IIcon {
        anchors.centerIn: parent
        icon: root.fallbackIcon
        pointSize: root.fallbackIconSize
        z: 0
      }
    }
  }

  // Border
  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: "transparent"
    border.color: parent.borderColor
    border.width: parent.borderWidth
    antialiasing: true
    z: 10
  }
}
