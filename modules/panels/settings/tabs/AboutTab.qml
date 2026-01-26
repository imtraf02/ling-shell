import QtQuick
import QtQuick.Layouts
import qs.common
import qs.widgets
import qs.services

ColumnLayout {
  id: root

  readonly property int padding: Style.padding.normal
  spacing: Style.spacing.larger

  IBox {
    Layout.fillWidth: true
    Layout.preferredHeight: asciiLayout.implicitHeight + root.padding * 2

    ColumnLayout {
      id: asciiLayout
      anchors.fill: parent
      anchors.topMargin: root.padding
      anchors.bottomMargin: root.padding
      spacing: Style.spacing.small

      IText {
        id: asciiText
        text: "██╗     ██╗███╗   ██╗ ██████╗\n██║     ██║████╗  ██║██╔════╝\n██║     ██║██╔██╗ ██║██║  ███╗\n██║     ██║██║╚██╗██║██║   ██║\n███████╗██║██║ ╚████║╚██████╔╝\n╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝"
        font.family: "Monospace"
        color: ThemeService.palette.mPrimary
        Layout.alignment: Qt.AlignHCenter
      }

      IText {
        text: "Ling Shell"
        color: ThemeService.palette.mPrimary
        font.pointSize: Style.font.size.larger
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }
}
