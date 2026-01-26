import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.common
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
    anchors.leftMargin: Style.padding.small
    anchors.rightMargin: Style.padding.small
    anchors.margins: Style.padding.small

    IconImage {
      id: icon

      source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
      implicitSize: parent.height * 0.8

      anchors.verticalCenter: parent.verticalCenter
    }

    Item {
      anchors.left: icon.right
      anchors.leftMargin: Style.padding.small
      anchors.verticalCenter: icon.verticalCenter

      implicitWidth: parent.width - icon.width
      implicitHeight: name.implicitHeight + comment.implicitHeight

      IText {
        id: name

        text: root.modelData?.name ?? ""
        font.pointSize: Style.font.size.larger
      }

      IText {
        id: comment

        text: (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
        font.pointSize: Style.font.size.smaller
        color: ThemeService.palette.mOutline

        elide: Text.ElideRight
        width: root.width - icon.width - Style.padding.small * 2

        anchors.top: name.bottom
      }
    }
  }
}
