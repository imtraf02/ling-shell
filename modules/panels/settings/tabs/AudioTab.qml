pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.config
import qs.commons
import qs.widgets
import qs.services

ColumnLayout {
  id: root

  readonly property int padding: Config.appearance.padding.normal
  spacing: Config.appearance.spacing.larger

  property real localVolume: AudioService.volume

  Connections {
    target: AudioService.sink?.audio ? AudioService.sink?.audio : null
    function onVolumeChanged() {
      root.localVolume = AudioService.volume;
    }
  }

  ILabel {
    label: "Volumes"
    description: "Adjust volume controls and audio levels."
    labelSize: Config.appearance.font.size.large
    descriptionSize: Config.appearance.font.size.smaller
  }

  ILabel {
    label: "Output volume"
    description: "System-wide volume level."
  }

  Timer {
    interval: 100
    running: true
    repeat: true
    onTriggered: {
      if (Math.abs(root.localVolume - AudioService.volume) >= 0.01) {
        AudioService.setVolume(root.localVolume);
      }
    }
  }

  IValueSlider {
    Layout.fillWidth: true
    from: 0
    to: Settings.audio.volumeOverdrive ? 1.5 : 1.0
    value: root.localVolume
    stepSize: 0.01
    text: Math.round(AudioService.volume * 100) + "%"
    onMoved: value => root.localVolume = value
  }

  IToggle {
    label: "Mute audio output"
    description: "Mute the system's main audio output."
    checked: AudioService.muted
    onToggled: checked => {
      if (AudioService.sink && AudioService.sink.audio) {
        AudioService.sink.audio.muted = checked;
      }
    }
  }

  ILabel {
    label: "Input volume"
    description: "Microphone input volume level."
  }

  IValueSlider {
    Layout.fillWidth: true
    from: 0
    to: Settings.audio.volumeOverdrive ? 1.5 : 1.0
    value: AudioService.inputVolume
    stepSize: 0.01
    text: Math.round(AudioService.inputVolume * 100) + "%"
    onMoved: value => AudioService.setInputVolume(value)
  }

  IToggle {
    label: "Mute input"
    description: "Mute the default audio input (microphone)."
    checked: AudioService.inputMuted
    onToggled: checked => AudioService.setInputMuted(checked)
  }

  ISpinBox {
    Layout.fillWidth: true
    label: "Volume step size"
    description: "Adjust the step size for volume changes (scroll wheel, keyboard shortcuts)."
    minimum: 1
    maximum: 25
    value: Settings.audio.volumeStep
    stepSize: 1
    suffix: "%"
    onValueChanged: Settings.audio.volumeStep = value
  }

  IToggle {
    label: "Allow volume overdrive"
    description: "Allow raising volume above 100%. May not be supported by all hardware."
    checked: Settings.audio.volumeOverdrive
    onToggled: checked => Settings.audio.volumeOverdrive = checked
  }

  IDivider {
    Layout.fillWidth: true
    Layout.topMargin: root.padding
    Layout.bottomMargin: root.padding
  }

  ILabel {
    label: "Audio devices"
    description: "Configure available audio input and output devices."
    labelSize: Config.appearance.font.size.large
    descriptionSize: Config.appearance.font.size.smaller
  }

  ButtonGroup {
    id: sinks
  }

  ILabel {
    label: "Output device"
    description: "Select the desired audio output device."
  }

  Repeater {
    model: AudioService.sinks
    IRadioButton {
      ButtonGroup.group: sinks
      required property PwNode modelData
      text: modelData.description
      checked: AudioService.sink?.id === modelData.id
      onClicked: {
        AudioService.setAudioSink(modelData);
        root.localVolume = AudioService.volume;
      }
      Layout.fillWidth: true
    }
  }

  ButtonGroup {
    id: sources
  }

  ILabel {
    label: "Input device"
    description: "Select the desired audio input device."
  }

  Repeater {
    model: AudioService.sources
    IRadioButton {
      ButtonGroup.group: sources
      required property PwNode modelData
      text: modelData.description
      checked: AudioService.source?.id === modelData.id
      onClicked: AudioService.setAudioSource(modelData)
      Layout.fillWidth: true
    }
  }

  IDivider {
    Layout.fillWidth: true
    Layout.topMargin: root.padding
    Layout.bottomMargin: root.padding
  }

  // TODO: Media player
}
