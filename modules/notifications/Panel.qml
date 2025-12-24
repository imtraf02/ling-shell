import QtQuick
import qs.config
import qs.widgets

Item {
  id: root

  required property var panel

  visible: height > 0
  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

  states: State {
    name: "hidden"
    when: root.panel.shouldBeActive

    PropertyChanges {
      root.implicitHeight: 0
    }
  }

  transitions: Transition {
    IAnim {
      target: root
      property: "implicitHeight"
      duration: Config.appearance.anim.durations.expressiveDefaultSpatial
      easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
    }
  }

  Content {
    id: content
  }
}
