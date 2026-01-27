import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Rectangle {
  id: root

  property int currentIndex: 0
  property int spacing: Style.spacing.small
  default property alias content: tabRow.children

  Layout.fillWidth: true
  implicitHeight: Style.widget.size + Style.padding.small * 2
  color: ThemeService.palette.mSurfaceVariant
  radius: Style.rounding.small

  RowLayout {
    id: tabRow
    anchors.fill: parent
    anchors.margins: Style.padding.small
    spacing: Style.spacing.small
  }
}
