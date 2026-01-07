pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.commons
import qs.widgets
import qs.services

Item {
  id: root

  required property ShellScreen screen

  readonly property int padding: Math.max(Style.appearance.padding.small, Settings.appearance.thickness)
  readonly property int contentHeight: Style.bar.innerHeight + padding * 2
  readonly property int exclusiveZone: Settings.bar.persistent || VisibilityService.bar ? contentHeight : Settings.appearance.thickness

  readonly property bool shouldBeVisible: Settings.bar.persistent || VisibilityService.bar || VisibilityService.barIsHovered

  visible: height > Settings.appearance.thickness
  implicitHeight: Settings.appearance.thickness

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
        duration: Style.appearance.anim.durations.normal
        easing.bezierCurve: Style.appearance.anim.curves.expressiveDefaultSpatial
      }
    },
    Transition {
      from: "visible"
      to: ""
      IAnim {
        target: root
        property: "implicitHeight"
        easing.bezierCurve: Style.appearance.anim.curves.emphasized
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
        anchors.leftMargin: root.padding
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - root.padding * 2
        screen: root.screen
      }

      CenterSection {
        id: centerSection
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - root.padding * 2
        screen: root.screen
      }

      RightSection {
        id: rightSection
        anchors.right: parent.right
        anchors.rightMargin: root.padding
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - root.padding * 2
        screen: root.screen
      }
    }
  }
}
