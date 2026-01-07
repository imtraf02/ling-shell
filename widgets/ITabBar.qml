import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.services

Rectangle {
  id: root

  property int currentIndex: 0
  property int spacing: Style.appearance.spacing.small
  default property alias content: tabRow.children

  Layout.fillWidth: true
  implicitHeight: Style.appearance.widget.size + Style.appearance.padding.small * 2
  color: ThemeService.palette.mSurfaceVariant
  radius: Settings.appearance.cornerRadius

  RowLayout {
    id: tabRow
    anchors.fill: parent
    anchors.margins: Style.appearance.padding.small
    spacing: root.spacing
  }
}
