pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.modules.panels

SmartPanel {
  id: root

  panelContent: Item {
    id: panelContent
    anchors.fill: parent

    readonly property real contentPreferredWidth: Style.bar.calendarWidth
    readonly property real contentPreferredHeight: content.implicitHeight + (Style.padding.small * 2)

    ColumnLayout {
      id: content

      anchors.fill: parent
      anchors.margins: Style.padding.small

      Calendar {
        Layout.fillWidth: true
      }
    }
  }
}
