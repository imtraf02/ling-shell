pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import qs.commons
import qs.widgets
import qs.services

// TODO: Fix Performance
Item {
  id: root

  required property ShellScreen screen
  property bool shouldBeActive: false

  enum Tab {
    System,
    Personalization,
    Bar,
    Display,
    Audio,
    Network,
    Keybinds,
    About
  }

  property int requestedTab: Panel.Tab.System
  property int currentTabIndex: 0
  property var tabsModel: [
    {
      id: Panel.Tab.System,
      icon: "computer",
      label: "System"
    },
    {
      id: Panel.Tab.Personalization,
      icon: "palette",
      label: "Personalization"
    },
    {
      id: Panel.Tab.Bar,
      icon: "crop_16_9",
      label: "Bar"
    },
    {
      id: Panel.Tab.Display,
      icon: "tv",
      label: "Display"
    },
    {
      id: Panel.Tab.Audio,
      icon: "speaker",
      label: "Audio"
    },
    {
      id: Panel.Tab.Network,
      icon: "lan",
      label: "Network"
    },
    {
      id: Panel.Tab.Keybinds,
      icon: "keyboard",
      label: "Keybinds"
    },
    {
      id: Panel.Tab.About,
      icon: "info",
      label: "About"
    }
  ]

  readonly property int size: settingsIcon.implicitHeight + Style.appearance.padding.large * 4
  readonly property int radius: Settings.appearance.cornerRadius

  implicitWidth: size
  implicitHeight: size

  rotation: 180
  scale: 0

  onShouldBeActiveChanged: {
    if (shouldBeActive) {
      content.active = true;
      content.visible = true;
      hideAnim.stop();
      showAnim.restart();
    } else {
      showAnim.stop();
      hideAnim.restart();
    }
  }

  function toggle(button) {
    shouldBeActive ? close() : open(button);
  }

  function close() {
    shouldBeActive = false;
    VisibilityService.closedPanel(root);
  }

  function open() {
    shouldBeActive = true;
    VisibilityService.willOpenPanel(root);

    let initialIndex = 0;
    if (root.requestedTab !== null) {
      for (let i = 0; i < root.tabsModel.length; i++) {
        if (root.tabsModel[i].id === root.requestedTab) {
          initialIndex = i;
          break;
        }
      }
    }
    root.currentTabIndex = initialIndex;
  }

  ParallelAnimation {
    id: showAnim

    SequentialAnimation {
      ParallelAnimation {
        IAnim {
          target: root
          property: "scale"
          to: 1
          duration: Style.appearance.anim.durations.expressiveFastSpatial
          easing.bezierCurve: Style.appearance.anim.curves.expressiveFastSpatial
        }
        IAnim {
          target: root
          property: "rotation"
          to: 360
          duration: Style.appearance.anim.durations.expressiveFastSpatial
          easing.bezierCurve: Style.appearance.anim.curves.standardAccel
        }
      }

      ParallelAnimation {
        IAnim {
          target: settingsIcon
          property: "rotation"
          to: 360
          easing.bezierCurve: Style.appearance.anim.curves.standardDecel
        }
        IAnim {
          target: settingsIcon
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
          duration: Style.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.appearance.anim.curves.expressiveDefaultSpatial
        }
        IAnim {
          target: background
          property: "radius"
          to: Settings.appearance.cornerRadius * 1.5
        }
        IAnim {
          target: root
          property: "implicitWidth"
          to: root.screen.height * Style.settings.heightMult * Style.settings.ratio
          duration: Style.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.appearance.anim.curves.expressiveDefaultSpatial
        }
        IAnim {
          target: root
          property: "implicitHeight"
          to: root.screen.height * Style.settings.heightMult
          duration: Style.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Style.appearance.anim.curves.expressiveDefaultSpatial
        }
      }
    }
  }

  SequentialAnimation {
    id: hideAnim

    ParallelAnimation {
      IAnim {
        target: root
        property: "opacity"
        to: 0
        duration: Style.appearance.anim.durations.small
        easing.bezierCurve: Style.appearance.anim.curves.standardDecel
      }
      IAnim {
        target: root
        property: "scale"
        from: 1
        to: 0.95
        duration: Style.appearance.anim.durations.small
        easing.bezierCurve: Style.appearance.anim.curves.standardDecel
      }
    }

    ScriptAction {
      script: {
        content.visible = false;
        content.active = false;
        content.opacity = 0;
        content.scale = 0;
        settingsIcon.opacity = 1;
        settingsIcon.rotation = 180;
        background.radius = root.radius;
        root.rotation = 180;
        root.scale = 0;
        root.opacity = 1;
        root.implicitWidth = root.size;
        root.implicitHeight = root.size;
      }
    }
  }

  Rectangle {
    id: background
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
    id: settingsIcon

    anchors.centerIn: parent
    icon: "settings"
    pointSize: Style.appearance.font.size.extraLarge * 4
    font.bold: true
    rotation: 180
  }

  Loader {
    id: content
    visible: false
    active: false
    opacity: 0
    scale: 0
    anchors.fill: parent
    anchors.margins: Style.appearance.padding.normal
    sourceComponent: Content {
      panel: root
    }
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.shouldBeActive
    onActivated: root.close()
  }
}
