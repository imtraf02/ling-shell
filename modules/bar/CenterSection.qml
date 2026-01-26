pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.modules.bar.widgets

RowLayout {
  id: root

  property ShellScreen screen

  readonly property list<string> entries: ["Clock"]

  spacing: Style.spacing.small

  Repeater {
    model: root.entries
    delegate: Loader {
      required property string modelData

      asynchronous: true
      sourceComponent: widgetFactory.createComponent(modelData)
    }
  }

  QtObject {
    id: widgetFactory

    function createComponent(widgetName) {
      switch (widgetName) {
      case "Clock":
        return clockComponent;
      default:
        return null;
      }
    }
  }

  Component {
    id: clockComponent
    Clock {
      screen: root.screen
    }
  }
}
