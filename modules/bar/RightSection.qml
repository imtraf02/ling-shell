pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import "widgets"

RowLayout {
  id: root
  property ShellScreen screen

  readonly property list<string> widgetsList: ["Tray", "Notifications", "Battery", "Volume", "Wifi", "Brightness"]

  spacing: Config.appearance.spacing.small

  Repeater {
    model: root.widgetsList
    delegate: Loader {
      required property string modelData

      asynchronous: false
      sourceComponent: widgetFactory.createComponent(modelData)
    }
  }

  QtObject {
    id: widgetFactory

    function createComponent(widgetName) {
      switch (widgetName) {
      case "Tray":
        return trayComponent;
      case "Notifications":
        return notificationsComponent;
      case "Battery":
        return batteryComponent;
      case "Volume":
        return volumeComponent;
      case "Wifi":
        return wifiComponent;
      case "Brightness":
        return brightnessComponent;
      default:
        return null;
      }
    }
  }

  Component {
    id: trayComponent
    Tray {
      screen: root.screen
    }
  }
  Component {
    id: notificationsComponent
    Notifications {
      screen: root.screen
    }
  }
  Component {
    id: batteryComponent
    Battery {
      screen: root.screen
    }
  }
  Component {
    id: volumeComponent
    Volume {
      screen: root.screen
    }
  }
  Component {
    id: wifiComponent
    Wifi {
      screen: root.screen
    }
  }
  Component {
    id: brightnessComponent
    Brightness {
      screen: root.screen
    }
  }
}
