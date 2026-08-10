import QtQuick
import QtQuick.Layouts
import qs.common

GridLayout {
  id: root

  readonly property bool twoColumns: width >= 760
  columns: twoColumns ? 2 : 1
  columnSpacing: Style.spacing.normal
  rowSpacing: Style.spacing.normal
  Layout.fillWidth: true
}
