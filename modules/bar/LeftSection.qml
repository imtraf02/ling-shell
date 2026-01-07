pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.commons
import "widgets"

RowLayout {
  id: root

  property ShellScreen screen

  readonly property list<string> widgetsList: ["OsIcon", "Workspace", "Media"]

  spacing: Style.appearance.spacing.small

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
      case "OsIcon":
        return osIconComponent;
      case "Workspace":
        return workspaceComponent;
      case "Media":
        return mediaComponent;
      default:
        return null;
      }
    }
  }

  Component {
    id: osIconComponent
    OsIcon {
      screen: root.screen
    }
  }
  Component {
    id: workspaceComponent
    Workspace {
      screen: root.screen
    }
  }
  Component {
    id: mediaComponent
    Media {
      screen: root.screen
    }
  }
}
