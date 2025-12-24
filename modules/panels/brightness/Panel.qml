pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.commons
import qs.widgets
import qs.services
import ".."

BarPanel {
  id: root

  contentComponent: Item {
    id: content

    implicitWidth: Config.bar.sizes.brightnessWidth
    implicitHeight: mainColumn.implicitHeight + (root.padding * 2)

    ColumnLayout {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: root.padding
      spacing: root.spacing

      Repeater {
        model: Quickshell.screens || []

        delegate: IBox {
          id: box
          required property ShellScreen modelData

          Layout.fillWidth: true
          implicitHeight: contentCol.implicitHeight + contentCol.anchors.margins * 2

          property var brightnessMonitor: BrightnessService.getMonitorForScreen(modelData)

          ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: root.spacing

            ILabel {
              label: box.modelData.name || "Unknown"
              description: {
                const compositorScale = CompositorService.getDisplayScale(box.modelData.name);
                return `${box.modelData.model} (${box.modelData.width * compositorScale}x${box.modelData.height * compositorScale} @ ${compositorScale}x)`;
              }
            }

            ColumnLayout {
              spacing: root.spacing
              Layout.fillWidth: true
              visible: box.brightnessMonitor !== undefined && box.brightnessMonitor !== null

              RowLayout {
                Layout.fillWidth: true
                spacing: root.spacing

                IText {
                  text: "Brightness"
                  Layout.preferredWidth: 90
                  Layout.alignment: Qt.AlignVCenter
                }

                IValueSlider {
                  id: brightnessSlider
                  from: 0
                  to: 1
                  stepSize: 0.01
                  Layout.fillWidth: true

                  value: box.brightnessMonitor ? box.brightnessMonitor.brightness : 0.5
                  enabled: box.brightnessMonitor ? box.brightnessMonitor.brightnessControlAvailable : false

                  onMoved: value => {
                    if (box.brightnessMonitor && box.brightnessMonitor.brightnessControlAvailable)
                      box.brightnessMonitor.setBrightness(value);
                  }

                  onPressedChanged: (pressed, value) => {
                    if (box.brightnessMonitor && box.brightnessMonitor.brightnessControlAvailable)
                      box.brightnessMonitor.setBrightness(value);
                  }
                }

                IText {
                  text: box.brightnessMonitor ? Math.round(brightnessSlider.value * 100) + "%" : "N/A"
                  Layout.preferredWidth: 55
                  Layout.alignment: Qt.AlignVCenter
                  horizontalAlignment: Text.AlignRight
                  opacity: box.brightnessMonitor && !box.brightnessMonitor.brightnessControlAvailable ? 0.5 : 1.0
                }

                Item {
                  Layout.preferredWidth: 30
                  Layout.fillHeight: true

                  IIcon {
                    icon: box.brightnessMonitor && box.brightnessMonitor.method == "internal" ? "laptop_windows" : "desktop_windows"
                    anchors.centerIn: parent
                    opacity: box.brightnessMonitor && !box.brightnessMonitor.brightnessControlAvailable ? 0.5 : 1.0
                  }
                }
              }

              // Show message when brightness control is not available
              IText {
                visible: box.brightnessMonitor && !box.brightnessMonitor.brightnessControlAvailable || true
                text: !Settings.brightness.enableDdcSupport ? "Brightness control unavailable. Enable \"External brightness support\" to control this display's brightness." : "Brightness control is not available for this display."
                pointSize: Config.appearance.font.size.small
                color: ThemeService.palette.mOnSurfaceVariant
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
              }
            }
          }
        }
      }
    }
  }
}
