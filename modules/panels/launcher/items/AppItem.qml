import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.commons
import qs.services
import qs.widgets
import qs.modules.panels.launcher.services

Item {
  id: root
  required property DesktopEntry modelData

  implicitHeight: Style.launcher.itemHeight

  anchors.left: parent?.left
  anchors.right: parent?.right

  signal clicked

  IStateLayer {
    radius: Settings.appearance.cornerRadius

    function onClicked(): void {
      AppsService.launch(root.modelData);
      root.clicked();
    }
  }

  Item {
    anchors.fill: parent
    anchors.leftMargin: Style.appearance.padding.small
    anchors.rightMargin: Style.appearance.padding.small
    anchors.margins: Style.appearance.padding.small

    IconImage {
      id: icon

      source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
      implicitSize: parent.height * 0.8

      anchors.verticalCenter: parent.verticalCenter
    }

    Item {
      anchors.left: icon.right
      anchors.leftMargin: Style.appearance.padding.small
      anchors.verticalCenter: icon.verticalCenter

      implicitWidth: parent.width - icon.width
      implicitHeight: name.implicitHeight + comment.implicitHeight

      IText {
        id: name

        text: root.modelData?.name ?? ""
        pointSize: Style.appearance.font.size.larger
      }

      IText {
        id: comment

        text: (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
        pointSize: Style.appearance.font.size.smaller
        color: ThemeService.palette.mOutline

        elide: Text.ElideRight
        width: root.width - icon.width - Style.appearance.padding.small * 2

        anchors.top: name.bottom
      }
    }
  }
}
