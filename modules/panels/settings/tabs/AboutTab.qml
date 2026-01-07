import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.widgets
import qs.services

ColumnLayout {
  id: root

  readonly property int padding: Style.appearance.padding.normal
  spacing: Style.appearance.spacing.larger

  IBox {
    Layout.fillWidth: true
    Layout.preferredHeight: asciiLayout.implicitHeight + root.padding * 2

    ColumnLayout {
      id: asciiLayout
      anchors.fill: parent
      anchors.topMargin: root.padding
      anchors.bottomMargin: root.padding
      spacing: Style.appearance.spacing.small

      IText {
        id: asciiText
        text: "██╗     ██╗███╗   ██╗ ██████╗\n██║     ██║████╗  ██║██╔════╝\n██║     ██║██╔██╗ ██║██║  ███╗\n██║     ██║██║╚██╗██║██║   ██║\n███████╗██║██║ ╚████║╚██████╔╝\n╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝"
        family: "Monospace"
        color: ThemeService.palette.mPrimary
        Layout.alignment: Qt.AlignHCenter
      }

      IText {
        text: "Ling Shell"
        color: ThemeService.palette.mPrimary
        pointSize: Style.appearance.font.size.larger
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }
}
