import QtQuick
import Quickshell
import qs.common
import qs.services
import qs.widgets

Item {
  id: root

  property ShellScreen screen
  property var panel
  readonly property bool historyPanelOpen: root.panel?.isPanelOpen === true

  visible: height > 0
  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

  states: State {
    name: "hidden"
    when: root.historyPanelOpen

    PropertyChanges {
      root.implicitHeight: 0
    }
  }

  transitions: Transition {
    IAnim {
      target: root
      property: "implicitHeight"
      duration: Style.anim.durations.expressiveDefaultSpatial
      easing.bezierCurve: Style.anim.curves.expressiveDefaultSpatial
    }
  }

  Content {
    id: content
  }
}
