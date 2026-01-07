import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.services
import qs.widgets
import qs.utils

Item {
  id: root

  required property var panel
  readonly property int padding: Style.appearance.padding.normal
  readonly property int spacing: Style.appearance.spacing.small

  property real localVolume: AudioService.volume || 0
  property bool volumeChanging: false

  function getMonitor() {
    return BrightnessService.getMonitorForScreen(panel.screen) || null;
  }

  Connections {
    target: AudioService.sink?.audio
    function onVolumeChanged() {
      if (!root.volumeChanging) {
        root.localVolume = AudioService.volume;
      }
    }
  }

  RowLayout {
    anchors.fill: parent
    spacing: root.spacing

    RowLayout {
      spacing: root.spacing

      IIconButton {
        icon: AudioService.getOutputIcon()
        border.width: 0
        colorFg: ThemeService.palette.mOnSurface
        colorBg: ThemeService.palette.mSurface
        colorBgHover: ThemeService.palette.mSurfaceContainer
        colorFgHover: ThemeService.palette.mPrimary

        onClicked: {
          if (AudioService.sink?.audio)
            AudioService.sink.audio.muted = !AudioService.muted;
        }
      }

      IValueSlider {
        Layout.fillWidth: true
        from: 0
        to: Settings.audio.volumeOverdrive ? 1.5 : 1.0
        value: root.localVolume
        stepSize: 0.01

        onMoved: v => {
          root.localVolume = v;
          AudioService.setVolume(v);
        }

        onPressedChanged: (pressed, v) => {
          root.volumeChanging = pressed;
          if (!pressed)
            AudioService.setVolume(v);
        }
      }
    }

    RowLayout {
      spacing: root.spacing

      IIconButton {
        icon: {
          const m = root.getMonitor();
          return m ? Icons.getBrightnessIcon(m.brightness) : "brightness_5";
        }

        border.width: 0
        colorFg: ThemeService.palette.mOnSurface
        colorBg: ThemeService.palette.mSurface
        colorBgHover: ThemeService.palette.mSurfaceContainer
        colorFgHover: ThemeService.palette.mPrimary

        onClicked: {
          const m = root.getMonitor();
          if (m?.brightnessControlAvailable)
            m.setBrightness(0.5);
        }
      }

      IValueSlider {
        Layout.fillWidth: true
        from: 0
        to: 1
        stepSize: 0.01

        value: {
          const m = root.getMonitor();
          return m ? m.brightness : 0.5;
        }

        onMoved: v => {
          const m = root.getMonitor();
          if (m?.brightnessControlAvailable)
            m.setBrightness(v);
        }

        onPressedChanged: (pressed, v) => {
          const m = root.getMonitor();
          if (m?.brightnessControlAvailable)
            m.setBrightness(v);
        }
      }
    }
  }
}
