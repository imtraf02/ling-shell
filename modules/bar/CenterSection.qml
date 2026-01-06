pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import "widgets"

RowLayout {
  id: root

  property ShellScreen screen

  readonly property list<string> widgetsList: ["Clock"]

  spacing: Config.appearance.spacing.small

  Repeater {
    model: root.widgetsList
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
