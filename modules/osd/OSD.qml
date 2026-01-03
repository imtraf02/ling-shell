pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.commons
import qs.config
import qs.services
import qs.widgets
import qs.utils

Variants {
  model: Quickshell.screens

  PanelWindow {
    id: panel

    required property var modelData
    screen: modelData

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    anchors.bottom: true
    color: "transparent"

    // State management
    property string currentOSDType: ""
    readonly property var monitor: BrightnessService.getMonitorForScreen(screen) ?? null
    property real volume: AudioService.volume ?? 0
    property bool volumeChanging: false
    property bool muted: AudioService.muted
    property real inputVolume: AudioService.inputVolume ?? 0
    property bool inputVolumeChanging: false
    property bool inputMuted: AudioService.inputMuted
    property bool firstBrightnessReceived: false
    property real brightness: monitor?.brightness ?? 0

    // Consolidated value computation
    readonly property real currentValue: {
      switch (currentOSDType) {
      case "volume":
        return volume;
      case "input":
        return inputVolume;
      case "brightness":
        return brightness;
      default:
        return 0;
      }
    }

    readonly property bool currentMuted: {
      switch (currentOSDType) {
      case "volume":
        return muted;
      case "input":
        return inputMuted;
      default:
        return false;
      }
    }

    readonly property string currentIcon: {
      switch (currentOSDType) {
      case "volume":
        return AudioService.getOutputIcon();
      case "input":
        return AudioService.getInputIcon();
      case "brightness":
        return monitor ? Icons.getBrightnessIcon(monitor.brightness) : "brightness_5";
      default:
        return "";
      }
    }

    function showOSD(type) {
      currentOSDType = type;
      popup.visible = true;
      osdItem.opacity = 1;
      osdItem.scale = 1;
      hideTimer.restart();
    }

    Connections {
      target: AudioService

      function onVolumeChanged() {
        panel.showOSD("volume");
        if (!panel.volumeChanging) {
          panel.volume = AudioService.volume;
        }
      }

      function onMutedChanged() {
        panel.showOSD("volume");
      }

      function onInputVolumeChanged() {
        panel.showOSD("input");
        if (!panel.inputVolumeChanging) {
          panel.inputVolume = AudioService.inputVolume;
        }
      }

      function onInputMutedChanged() {
        panel.showOSD("input");
      }
    }

    Connections {
      target: panel.monitor
      ignoreUnknownSignals: true

      function onBrightnessUpdated() {
        if (!panel.firstBrightnessReceived) {
          panel.firstBrightnessReceived = true;
          return;
        }
        panel.showOSD("brightness");
      }
    }

    Timer {
      id: hideTimer
      interval: 2000
      onTriggered: {
        osdItem.opacity = 0;
        osdItem.scale = 0.85;
        Qt.callLater(() => popup.visible = false);
      }
    }

    PopupWindow {
      id: popup

      anchor.window: panel
      anchor.rect.x: parentWindow.width / 2 - implicitWidth / 2
      anchor.rect.y: parentWindow.height - implicitHeight - 80
      implicitWidth: 320
      implicitHeight: 48
      visible: false
      color: "transparent"

      Item {
        id: osdItem
        anchors.fill: parent
        opacity: 0
        scale: 0.85

        Behavior on opacity {
          IAnim {}
        }
        Behavior on scale {
          IAnim {
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
          }
        }

        Rectangle {
          id: background
          anchors.fill: parent
          radius: Settings.appearance.cornerRadius
          color: ThemeService.palette.mSurface
          border.color: Qt.alpha(ThemeService.palette.mOutline, 0.2)
          border.width: 1

          layer.enabled: true
          layer.effect: MultiEffect {
            source: background
            shadowEnabled: true
            blurMax: 22
            shadowBlur: 1
            shadowOpacity: 0.85
            shadowColor: "#000000"
            shadowHorizontalOffset: 2
            shadowVerticalOffset: 3
          }
        }

        RowLayout {
          anchors.fill: parent
          anchors.margins: Config.appearance.padding.normal
          spacing: Config.appearance.spacing.normal

          IIcon {
            id: icon
            icon: panel.currentIcon
            pointSize: Config.appearance.font.size.large
            color: panel.currentMuted ? ThemeService.palette.mError : ThemeService.palette.mOnSurface
            scale: iconScale.running ? 1.2 : 1.0

            Behavior on color {
              ICAnim {}
            }
            Behavior on scale {
              IAnim {
                easing.type: Easing.OutBack
              }
            }

            SequentialAnimation {
              id: iconScale
              running: popup.visible
              IAnim {
                target: icon
                property: "scale"
                to: 1.2
                duration: 100
                easing.type: Easing.OutQuad
              }
              IAnim {
                target: icon
                property: "scale"
                to: 1.0
                easing.type: Easing.OutBack
              }
            }
          }

          IValueSlider {
            id: osdSlider
            Layout.fillWidth: true
            heightRatio: 0.5
            snapAlways: false
            cutoutColor: ThemeService.palette.mSurface
            from: 0
            to: (panel.currentOSDType === "volume" || panel.currentOSDType === "input") && Settings.audio.volumeOverdrive ? 1.5 : 1.0
            value: panel.currentValue

            onMoved: v => {
              switch (panel.currentOSDType) {
              case "volume":
                panel.volume = v;
                AudioService.setVolume(v);
                break;
              case "input":
                panel.inputVolume = v;
                AudioService.setInputVolume(v);
                break;
              case "brightness":
                if (panel.monitor?.brightnessControlAvailable) {
                  panel.monitor.setBrightness(v);
                }
                break;
              }
            }

            onPressedChanged: (pressed, v) => {
              pressed ? hideTimer.stop() : hideTimer.restart();

              if (panel.currentOSDType === "volume") {
                panel.volumeChanging = pressed;
                if (!pressed)
                  AudioService.setVolume(v);
              } else if (panel.currentOSDType === "input") {
                panel.inputVolumeChanging = pressed;
                if (!pressed)
                  AudioService.setInputVolume(v);
              } else if (panel.monitor?.brightnessControlAvailable) {
                panel.monitor.setBrightness(v);
              }
            }
          }

          IText {
            id: valueText
            text: Math.round(panel.currentValue * 100) + "%"
            color: ThemeService.palette.mOnSurface
            pointSize: Config.appearance.font.size.larger
            family: Settings.appearance.font.mono
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            Layout.minimumWidth: 40
            scale: textScale.running ? 1.15 : 1.0

            Behavior on scale {
              IAnim {
                easing.type: Easing.OutBack
              }
            }

            Behavior on text {
              SequentialAnimation {
                IAnim {
                  target: valueText
                  property: "scale"
                  to: 1.15
                  duration: 100
                  easing.type: Easing.OutQuad
                }
                IAnim {
                  target: valueText
                  property: "scale"
                  to: 1.0
                  easing.type: Easing.OutBack
                }
              }
            }

            SequentialAnimation {
              id: textScale
              running: popup.visible
              PauseAnimation {
                duration: 50
              }
              IAnim {
                target: valueText
                property: "scale"
                to: 1.15
                duration: 100
                easing.type: Easing.OutQuad
              }
              IAnim {
                target: valueText
                property: "scale"
                to: 1.0
                easing.type: Easing.OutBack
              }
            }
          }
        }
      }
    }
  }
}
