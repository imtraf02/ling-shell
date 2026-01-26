pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.common
import qs.widgets
import qs.services

Item {
  id: root

  required property ShellScreen screen

  readonly property int padding: Math.max(Style.padding.small, Settings.appearance.thickness)
  readonly property int contentHeight: Style.bar.innerHeight + padding * 2
  readonly property int exclusiveZone: Settings.bar.persistent || BarService.isVisible ? contentHeight : Settings.appearance.thickness

  readonly property bool shouldBeVisible: Settings.bar.persistent || BarService.isVisible || BarService.isHovered

  visible: height > Settings.appearance.thickness
  implicitHeight: Settings.appearance.thickness

  onVisibleChanged: {
    if (visible) {
      CavaService.registerComponent("bar");
    } else {
      CavaService.unregisterComponent("bar");
    }
  }

  states: State {
    name: "visible"
    when: root.shouldBeVisible
    PropertyChanges {
      root.implicitHeight: root.contentHeight
    }
  }

  transitions: [
    Transition {
      from: ""
      to: "visible"
      IAnim {
        target: root
        property: "implicitHeight"
        duration: Style.anim.durations.normal
        easing.bezierCurve: Style.anim.curves.expressiveDefaultSpatial
      }
    },
    Transition {
      from: "visible"
      to: ""
      IAnim {
        target: root
        property: "implicitHeight"
        easing.bezierCurve: Style.anim.curves.emphasized
      }
    }
  ]

  Loader {
    id: content
    anchors.fill: parent

    active: root.shouldBeVisible || root.visible

    sourceComponent: Item {
      id: bar
      anchors.fill: parent
      clip: true

      LeftSection {
        id: leftSection
        anchors.left: parent.left
        anchors.leftMargin: Style.padding.small
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - Style.padding.small * 2
        screen: root.screen
      }

      CenterSection {
        id: centerSection
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - Style.padding.small * 2
        screen: root.screen
      }

      RightSection {
        id: rightSection
        anchors.right: parent.right
        anchors.rightMargin: Style.padding.small
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - Style.padding.small * 2
        screen: root.screen
      }
    }
  }
}
