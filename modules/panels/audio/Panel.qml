pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import qs.common
import qs.widgets
import qs.services
import qs.modules.panels

SmartPanel {
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
    running: root.isPanelOpen
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

  panelContent: Item {
    id: panelContent
    anchors.fill: parent

    readonly property real contentPreferredWidth: Style.bar.audioWidth
    readonly property real contentPreferredHeight: content.implicitHeight + (Style.padding.small * 2)

    ColumnLayout {
      id: content
      anchors.fill: parent
      anchors.margins: Style.padding.small
      spacing: Style.spacing.small

      IBox {
        id: headerBox
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + headerRow.anchors.margins * 2

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.padding.normal
          spacing: Style.spacing.small

          IIcon {
            icon: "media_output"
            color: ThemeService.palette.mPrimary
          }

          IText {
            text: "Audio"
            font.pointSize: Style.font.size.larger
            color: ThemeService.palette.mOnSurface
            Layout.fillWidth: true
          }

          IIconButton {
            icon: AudioService.getOutputIcon()
            size: Style.widget.size * 0.8
            onClicked: AudioService.setOutputMuted(!AudioService.muted)
          }

          IIconButton {
            icon: AudioService.getInputIcon()
            size: Style.widget.size * 0.8
            onClicked: AudioService.setInputMuted(!AudioService.inputMuted)
          }

          IIconButton {
            icon: "close"
            size: Style.widget.size * 0.8
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
          anchors.margins: Style.padding.small
          clip: true
          contentWidth: parent.width
          contentHeight: outputColumn.height
          boundsBehavior: Flickable.StopAtBounds

          ColumnLayout {
            id: outputColumn
            width: outputFlickable.width
            spacing: Style.spacing.small

            ButtonGroup {
              id: sinks
            }

            IText {
              text: "Output devices"
              font.pointSize: Style.font.size.larger
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
              Layout.bottomMargin: Style.spacing.small
            }

            Repeater {
              model: AudioService.sinks
              IRadioButton {
                ButtonGroup.group: sinks
                required property PwNode modelData
                font.pointSize: Style.font.size.small
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
          anchors.margins: Style.padding.normal
          clip: true
          contentWidth: parent.width
          contentHeight: inputColumn.height
          boundsBehavior: Flickable.StopAtBounds

          ColumnLayout {
            id: inputColumn
            width: inputFlickable.width
            spacing: Style.spacing.small

            ButtonGroup {
              id: sources
            }

            IText {
              text: "Input devices"
              font.pointSize: Style.font.size.larger
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
              Layout.bottomMargin: Style.spacing.small
            }

            Repeater {
              model: AudioService.sources
              IRadioButton {
                ButtonGroup.group: sources
                required property PwNode modelData
                font.pointSize: Style.font.size.small
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
