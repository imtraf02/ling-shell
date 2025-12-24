import QtQuick
import Quickshell
import qs.services
import qs.utils
import "../extras"

Item {
  id: root

  property ShellScreen screen
  property bool firstBrightnessReceived: false

  implicitWidth: pill.width
  implicitHeight: pill.height
  visible: monitor !== null

  readonly property var monitor: BrightnessService.getMonitorForScreen(screen) || null

  Connections {
    target: root.monitor
    ignoreUnknownSignals: true

    function onBrightnessUpdated() {
      if (!root.firstBrightnessReceived) {
        root.firstBrightnessReceived = true;
        return;
      }

      pill.show();
      hideTimer.restart();
    }
  }

  Timer {
    id: hideTimer
    interval: 2500
    running: false
    repeat: false
    onTriggered: pill.hide()
  }

  BarPill {
    id: pill

    icon: root.monitor ? Icons.getBrightnessIcon(root.monitor.brightness) : "brightness_5"

    text: root.monitor ? Math.round(root.monitor.brightness * 100) : ""
    suffix: "%"

    onWheel: function (angle) {
      if (!root.monitor)
        return;
      if (angle > 0)
        root.monitor.increaseBrightness();
      else if (angle < 0)
        root.monitor.decreaseBrightness();
    }

    onClicked: {
      VisibilityService.getPanel("brightness", root.screen)?.toggle(this);
    }
  }
}
