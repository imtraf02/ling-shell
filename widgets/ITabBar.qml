import QtQuick
import QtQuick.Layouts
import qs.config
import qs.commons
import qs.services

Rectangle {
  id: root

  property int currentIndex: 0
  property int spacing: Config.appearance.spacing.small
  default property alias content: tabRow.children

  Layout.fillWidth: true
  implicitHeight: Config.appearance.widget.size + Config.appearance.padding.small * 2
  color: ThemeService.palette.mSurfaceVariant
  radius: Settings.appearance.cornerRadius

  RowLayout {
    id: tabRow
    anchors.fill: parent
    anchors.margins: Config.appearance.padding.small
    spacing: root.spacing
  }
}
