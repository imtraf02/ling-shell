import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets
import qs.services

ColumnLayout {
  id: root

  readonly property int padding: Config.appearance.padding.normal
  spacing: Config.appearance.spacing.larger

  IBox {
    Layout.fillWidth: true
    Layout.preferredHeight: asciiLayout.implicitHeight + root.padding * 2

    ColumnLayout {
      id: asciiLayout
      anchors.fill: parent
      anchors.topMargin: root.padding
      anchors.bottomMargin: root.padding
      spacing: Config.appearance.spacing.small

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
        pointSize: Config.appearance.font.size.larger
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }
}
