pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.panels.controlcenter.widgets
import ".."

BarPanel {
  id: root

  readonly property int padding: Config.appearance.padding.normal
  readonly property int spacing: Config.appearance.spacing.small

  contentComponent: Item {
    id: content

    implicitWidth: 480
    implicitHeight: layout.implicitHeight + root.padding * 2

    ColumnLayout {
      id: layout
      anchors.fill: parent
      anchors.margins: root.padding
      spacing: root.spacing

      ProfileCard {
        Layout.fillWidth: true
        Layout.preferredHeight: 64

        panel: root
        padding: root.padding
        spacing: root.spacing
      }

      ControlSlidersCard {
        Layout.fillWidth: true
        Layout.preferredHeight: 52
        panel: root
      }

      ControlCenterPills {
        Layout.fillWidth: true
        panel: root
      }
    }
  }
}
