import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.commons
import qs.services
import qs.widgets
import qs.modules.panels.launcher.services

Item {
  id: root
  required property DesktopEntry modelData

  implicitHeight: Config.launcher.sizes.itemHeight

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
    anchors.leftMargin: Config.appearance.padding.small
    anchors.rightMargin: Config.appearance.padding.small
    anchors.margins: Config.appearance.padding.small

    IconImage {
      id: icon

      source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
      implicitSize: parent.height * 0.8

      anchors.verticalCenter: parent.verticalCenter
    }

    Item {
      anchors.left: icon.right
      anchors.leftMargin: Config.appearance.padding.small
      anchors.verticalCenter: icon.verticalCenter

      implicitWidth: parent.width - icon.width
      implicitHeight: name.implicitHeight + comment.implicitHeight

      IText {
        id: name

        text: root.modelData?.name ?? ""
        pointSize: Config.appearance.font.size.larger
      }

      IText {
        id: comment

        text: (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
        pointSize: Config.appearance.font.size.smaller
        color: ThemeService.palette.mOutline

        elide: Text.ElideRight
        width: root.width - icon.width - Config.appearance.padding.small * 2

        anchors.top: name.bottom
      }
    }
  }
}
