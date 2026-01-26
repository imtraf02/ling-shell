pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.widgets
import qs.modules.panels
import qs.modules.panels.controlcenter

SmartPanel {
  id: root

  panelContent: Item {
    id: panelContent
    anchors.fill: parent

    readonly property real contentPreferredWidth: Style.bar.controlCenterWidth
    readonly property real contentPreferredHeight: content.implicitHeight + (Style.padding.small * 2)

    ColumnLayout {
      id: content

      anchors.fill: parent
      anchors.margins: Style.padding.small

      ProfileCard {
        Layout.fillWidth: true
        Layout.preferredHeight: 64

        panel: root
      }

      IDivider {
        Layout.fillWidth: true
      }

      VolumeBrightnessSliders {
        Layout.fillWidth: true
        panel: root
      }

      IDivider {
        Layout.fillWidth: true
      }

      QuickToggles {
        Layout.fillWidth: true
        panel: root
      }
    }
  }
}
