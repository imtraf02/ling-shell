pragma ComponentBehavior: Bound

import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.config
import qs.commons
import qs.widgets
import qs.services

WlSessionLockSurface {
  id: root

  required property WlSessionLock lock
  required property Pam pam

  readonly property alias unlocking: unlockAnim.running

  color: "transparent"

  Connections {
    target: root.lock

    function onUnlock(): void {
      unlockAnim.start();
      VisibilityService.locked = false;
    }
  }

  SequentialAnimation {
    id: unlockAnim

    ParallelAnimation {
      IAnim {
        target: lockContent
        properties: "implicitWidth,implicitHeight"
        to: lockContent.size
        duration: Config.appearance.anim.durations.expressiveDefaultSpatial
        easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
      }
      IAnim {
        target: lockBg
        property: "radius"
        to: lockContent.radius
      }
      IAnim {
        target: content
        property: "scale"
        to: 0
        duration: Config.appearance.anim.durations.expressiveDefaultSpatial
        easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
      }
      IAnim {
        target: content
        property: "opacity"
        to: 0
        duration: Config.appearance.anim.durations.small
      }
      IAnim {
        target: lockIcon
        property: "opacity"
        to: 1
        duration: Config.appearance.anim.durations.large
      }
      SequentialAnimation {
        PauseAnimation {
          duration: Config.appearance.anim.durations.small
        }
        IAnim {
          target: lockContent
          property: "opacity"
          to: 0
        }
      }
    }
    PropertyAction {
      target: root.lock
      property: "locked"
      value: false
    }
  }

  ParallelAnimation {
    id: initAnim

    running: true

    SequentialAnimation {
      ParallelAnimation {
        IAnim {
          target: lockContent
          property: "scale"
          to: 1
          duration: Config.appearance.anim.durations.expressiveFastSpatial
          easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
        }
        IAnim {
          target: lockContent
          property: "rotation"
          to: 360
          duration: Config.appearance.anim.durations.expressiveFastSpatial
          easing.bezierCurve: Config.appearance.anim.curves.standardAccel
        }
      }
      ParallelAnimation {
        IAnim {
          target: lockIcon
          property: "rotation"
          to: 360
          easing.bezierCurve: Config.appearance.anim.curves.standardDecel
        }
        IAnim {
          target: lockIcon
          property: "opacity"
          to: 0
        }
        IAnim {
          target: content
          property: "opacity"
          to: 1
        }
        IAnim {
          target: content
          property: "scale"
          to: 1
          duration: Config.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
        }
        IAnim {
          target: lockBg
          property: "radius"
          to: Settings.appearance.cornerRadius * 1.5
        }
        IAnim {
          target: lockContent
          property: "implicitWidth"
          to: root.screen.height * Config.lock.sizes.heightMult * Config.lock.sizes.ratio
          duration: Config.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
        }
        IAnim {
          target: lockContent
          property: "implicitHeight"
          to: root.screen.height * Config.lock.sizes.heightMult
          duration: Config.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
        }
      }
    }
  }

  Image {
    id: lockBgImage
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
    source: root.screen ? WallpaperService.getWallpaper(root.screen.name) : ""
    cache: true
    smooth: true
    mipmap: false
  }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop {
        position: 0.0
        color: Qt.alpha(ThemeService.palette.mShadow, 0.8)
      }
      GradientStop {
        position: 0.3
        color: Qt.alpha(ThemeService.palette.mShadow, 0.4)
      }
      GradientStop {
        position: 0.7
        color: Qt.alpha(ThemeService.palette.mShadow, 0.5)
      }
      GradientStop {
        position: 1.0
        color: Qt.alpha(ThemeService.palette.mShadow, 0.9)
      }
    }
  }

  Item {
    id: lockContent

    readonly property int size: lockIcon.implicitHeight + Config.appearance.padding.large * 4
    readonly property int radius: Settings.appearance.cornerRadius

    anchors.centerIn: parent
    implicitWidth: size
    implicitHeight: size

    rotation: 180
    scale: 0

    Rectangle {
      id: lockBg

      anchors.fill: parent
      color: ThemeService.palette.mSurface
      radius: parent.radius
      opacity: 1

      layer.enabled: true
      layer.effect: MultiEffect {
        shadowEnabled: true
        blurMax: 15
        shadowColor: Qt.alpha(ThemeService.palette.mShadow, 0.7)
      }
    }

    IIcon {
      id: lockIcon

      anchors.centerIn: parent
      icon: "lock"
      pointSize: Config.appearance.font.size.extraLarge * 4
      font.bold: true
      rotation: 180
    }

    Content {
      id: content

      anchors.centerIn: parent
      width: (root.screen?.height ?? 0) * Config.lock.sizes.heightMult * Config.lock.sizes.ratio - Config.appearance.padding.large * 2
      height: (root.screen?.height ?? 0) * Config.lock.sizes.heightMult - Config.appearance.padding.large * 2

      lock: root
      opacity: 0
      scale: 0
    }
  }
}
