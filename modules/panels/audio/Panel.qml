pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import qs.commons
import qs.widgets
import qs.services
import ".."

BarPanel {
  id: root

  property real localOutputVolume: AudioService.volume || 0
  property bool localOutputVolumeChanging: false

  property real localInputVolume: AudioService.inputVolume || 0
  property bool localInputVolumeChanging: false

  Connections {
    target: AudioService.sink?.audio ? AudioService.sink?.audio : null
    function onVolumeChanged() {
      if (!root.localOutputVolumeChanging)
        root.localOutputVolume = AudioService.volume;
    }
  }

  Connections {
    target: AudioService.source?.audio ? AudioService.source?.audio : null
    function onVolumeChanged() {
      if (!root.localInputVolumeChanging)
        root.localInputVolume = AudioService.inputVolume;
    }
  }

  Timer {
    interval: 100
    running: true
    repeat: true
    onTriggered: {
      if (Math.abs(root.localOutputVolume - AudioService.volume) >= 0.01) {
        AudioService.setVolume(root.localOutputVolume);
      }
      if (Math.abs(root.localInputVolume - AudioService.inputVolume) >= 0.01) {
        AudioService.setInputVolume(root.localInputVolume);
      }
    }
  }

  contentComponent: Item {
    id: content

    implicitWidth: Style.bar.audioWidth
    implicitHeight: mainColumn.implicitHeight + root.padding * 2

    ColumnLayout {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: root.padding
      spacing: root.spacing

      IBox {
        id: headerBox
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + headerRow.anchors.margins * 2

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.appearance.padding.normal
          spacing: Style.appearance.spacing.small

          IIcon {
            icon: "media_output"
            color: ThemeService.palette.mPrimary
          }

          IText {
            text: "Audio"
            pointSize: Style.appearance.font.size.larger
            color: ThemeService.palette.mOnSurface
            Layout.fillWidth: true
          }

          IIconButton {
            icon: AudioService.getOutputIcon()
            size: Style.appearance.widget.size * 0.8
            onClicked: AudioService.setOutputMuted(!AudioService.muted)
          }

          IIconButton {
            icon: AudioService.getInputIcon()
            size: Style.appearance.widget.size * 0.8
            onClicked: AudioService.setInputMuted(!AudioService.inputMuted)
          }

          IIconButton {
            icon: "close"
            size: Style.appearance.widget.size * 0.8
            onClicked: root.close()
          }
        }
      }

      IBox {
        id: outputBox
        Layout.fillWidth: true
        implicitHeight: Math.min(outputColumn.implicitHeight + outputFlickable.anchors.margins * 2, 240)

        IFlickable {
          id: outputFlickable
          anchors.fill: parent
          anchors.margins: root.padding
          clip: true
          contentWidth: parent.width
          contentHeight: outputColumn.height
          boundsBehavior: Flickable.StopAtBounds

          ColumnLayout {
            id: outputColumn
            width: outputFlickable.width
            spacing: Style.appearance.spacing.small

            ButtonGroup {
              id: sinks
            }

            IText {
              text: "Output devices"
              pointSize: Style.appearance.font.size.larger
              color: ThemeService.palette.mPrimary
            }

            IValueSlider {
              Layout.fillWidth: true
              from: 0
              to: Settings.audio.volumeOverdrive ? 1.5 : 1.0
              value: root.localOutputVolume
              stepSize: 0.01
              heightRatio: 0.5
              onMoved: value => root.localOutputVolume = value
              onPressedChanged: (pressed, value) => root.localOutputVolumeChanging = pressed
              text: Math.round(root.localOutputVolume * 100) + "%"
              Layout.bottomMargin: Style.appearance.spacing.small
            }

            Repeater {
              model: AudioService.sinks
              IRadioButton {
                ButtonGroup.group: sinks
                required property PwNode modelData
                pointSize: Style.appearance.font.size.small
                text: modelData.description
                checked: AudioService.sink?.id === modelData.id
                onClicked: {
                  AudioService.setAudioSink(modelData);
                  root.localOutputVolume = AudioService.volume;
                }
                Layout.fillWidth: true
              }
            }
          }
        }
      }

      IBox {
        id: inputBox
        Layout.fillWidth: true
        implicitHeight: Math.min(inputColumn.implicitHeight + inputFlickable.anchors.margins * 2, 240)

        IFlickable {
          id: inputFlickable
          anchors.fill: parent
          anchors.margins: Style.appearance.padding.normal
          clip: true
          contentWidth: parent.width
          contentHeight: inputColumn.height
          boundsBehavior: Flickable.StopAtBounds

          ColumnLayout {
            id: inputColumn
            width: inputFlickable.width
            spacing: Style.appearance.spacing.small

            ButtonGroup {
              id: sources
            }

            IText {
              text: "Input devices"
              pointSize: Style.appearance.font.size.larger
              color: ThemeService.palette.mPrimary
            }

            IValueSlider {
              Layout.fillWidth: true
              from: 0
              to: Settings.audio.volumeOverdrive ? 1.5 : 1.0
              value: root.localInputVolume
              stepSize: 0.01
              heightRatio: 0.5
              onMoved: value => root.localInputVolume = value
              onPressedChanged: (pressed, value) => {
                root.localInputVolumeChanging = pressed;
              }
              text: Math.round(root.localInputVolume * 100) + "%"
              Layout.bottomMargin: Style.appearance.spacing.small
            }

            Repeater {
              model: AudioService.sources
              IRadioButton {
                ButtonGroup.group: sources
                required property PwNode modelData
                pointSize: Style.appearance.font.size.small
                text: modelData.description
                checked: AudioService.source?.id === modelData.id
                onClicked: AudioService.setAudioSource(modelData)
                Layout.fillWidth: true
              }
            }
          }
        }
      }
    }
  }
}
