import QtQuick
import Quickshell
import qs.services
import "../extras"

Item {
  id: root

  property ShellScreen screen

  property bool firstVolumeReceived: false
  property int wheelAccumulator: 0

  implicitWidth: pill.width
  implicitHeight: pill.height

  Connections {
    target: AudioService.sink?.audio ? AudioService.sink?.audio : null
    function onVolumeChanged() {
      if (!root.firstVolumeReceived) {
        root.firstVolumeReceived = true;
      } else {
        pill.show();
        externalHideTimer.restart();
      }
    }
  }

  Timer {
    id: externalHideTimer
    running: false
    interval: 1500
    onTriggered: {
      pill.hide();
    }
  }

  BarPill {
    id: pill
    icon: AudioService.getOutputIcon()
    text: Math.round(AudioService.volume * 100)
    suffix: "%"
    onWheel: function (delta) {
      root.wheelAccumulator += delta;
      if (root.wheelAccumulator >= 120) {
        root.wheelAccumulator = 0;
        AudioService.increaseVolume();
      } else if (root.wheelAccumulator <= -120) {
        root.wheelAccumulator = 0;
        AudioService.decreaseVolume();
      }
    }
    onClicked: {
      VisibilityService.getPanel("audio", root.screen)?.toggle(this);
    }
    onRightClicked: {
      AudioService.setOutputMuted(!AudioService.muted);
    }
  }
}
