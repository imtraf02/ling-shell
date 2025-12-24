pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.commons
import qs.widgets
import qs.services

ColumnLayout {
  id: root

  readonly property int padding: Config.appearance.padding.normal
  spacing: Config.appearance.spacing.larger

  ILabel {
    label: "Per-monitor settings"
    description: "Adjust settings brightness for each display."
    labelSize: Config.appearance.font.size.large
    descriptionSize: Config.appearance.font.size.smaller
  }

  Repeater {
    model: Quickshell.screens || []
    delegate: Rectangle {
      id: screenRect
      required property ShellScreen modelData

      Layout.fillWidth: true
      implicitHeight: contentCol.implicitHeight + root.padding * 2
      radius: Settings.appearance.cornerRadius
      color: ThemeService.palette.mSurfaceVariant
      border.color: ThemeService.palette.mOutline
      border.width: 1

      property var brightnessMonitor: BrightnessService.getMonitorForScreen(modelData)

      ColumnLayout {
        id: contentCol
        width: parent.width - 2 * root.padding
        x: root.padding
        y: root.padding
        spacing: root.spacing

        ILabel {
          label: screenRect.modelData.name || "Unknown"
          description: {
            const compositorScale = CompositorService.getDisplayScale(screenRect.modelData.name);
            return `${screenRect.modelData.model} (${screenRect.modelData.width * compositorScale}x${screenRect.modelData.height * compositorScale} @ ${compositorScale}x)`;
          }
        }

        ColumnLayout {
          spacing: Config.appearance.spacing.small
          Layout.fillWidth: true
          visible: screenRect.brightnessMonitor !== undefined && screenRect.brightnessMonitor !== null

          RowLayout {
            Layout.fillWidth: true
            spacing: Config.appearance.spacing.small

            IText {
              text: "Brightness"
              Layout.preferredWidth: 90
              Layout.alignment: Qt.AlignVCenter
            }

            IValueSlider {
              id: brightnessSlider
              from: 0
              to: 1
              value: screenRect.brightnessMonitor ? screenRect.brightnessMonitor.brightness : 0.5
              stepSize: 0.01
              enabled: screenRect.brightnessMonitor ? screenRect.brightnessMonitor.brightnessControlAvailable : false
              onMoved: value => {
                if (screenRect.brightnessMonitor && screenRect.brightnessMonitor.brightnessControlAvailable) {
                  screenRect.brightnessMonitor.setBrightness(value);
                }
              }
              onPressedChanged: (pressed, value) => {
                if (screenRect.brightnessMonitor && screenRect.brightnessMonitor.brightnessControlAvailable) {
                  screenRect.brightnessMonitor.setBrightness(value);
                }
              }
              Layout.fillWidth: true
            }

            IText {
              text: screenRect.brightnessMonitor ? Math.round(brightnessSlider.value * 100) + "%" : "N/A"
              Layout.preferredWidth: 55
              horizontalAlignment: Text.AlignRight
              Layout.alignment: Qt.AlignVCenter
              opacity: screenRect.brightnessMonitor && !screenRect.brightnessMonitor.brightnessControlAvailable ? 0.5 : 1.0
            }

            Item {
              Layout.preferredWidth: 30
              Layout.fillHeight: true
              IIcon {
                icon: screenRect.brightnessMonitor && screenRect.brightnessMonitor.method == "internal" ? "laptop_windows" : "desktop_windows"
                anchors.centerIn: parent
                opacity: screenRect.brightnessMonitor && !screenRect.brightnessMonitor.brightnessControlAvailable ? 0.5 : 1.0
              }
            }
          }

          IText {
            visible: screenRect.brightnessMonitor && !screenRect.brightnessMonitor.brightnessControlAvailable
            text: !Settings.brightness.enableDdcSupport ? "Brightness control unavailable. Enable \"External brightness support\" to control this display's brightness." : "Brightness control is not available for this display."
            color: ThemeService.palette.mOnSurfaceVariant
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }

  ISpinBox {
    Layout.fillWidth: true
    label: "Brightness step size"
    description: "Adjust the step size for brightness changes (scroll wheel and keyboard shortcuts)."
    minimum: 1
    maximum: 50
    value: Settings.brightness.brightnessStep
    stepSize: 1
    suffix: "%"
    onValueChanged: Settings.brightness.brightnessStep = value
  }

  IToggle {
    Layout.fillWidth: true
    label: "Enforce minimum brightness (1%)"
    description: "Solves the problem of backlight completely turning off on some displays at 0% brightness."
    checked: Settings.brightness.enforceMinimum
    onToggled: checked => Settings.brightness.enforceMinimum = checked
  }

  IToggle {
    Layout.fillWidth: true
    label: "External brightness support"
    description: "Enable DDCUtil support for controlling brightness on external displays via DDC/CI protocol."
    checked: Settings.brightness.enableDdcSupport
    onToggled: checked => {
      Settings.brightness.enableDdcSupport = checked;
    }
  }

  IDivider {
    Layout.fillWidth: true
    Layout.topMargin: root.padding
    Layout.bottomMargin: root.padding
  }
}
