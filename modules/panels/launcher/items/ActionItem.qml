import QtQuick
import qs.commons
import qs.services
import qs.widgets

Item {
  id: root

  required property var modelData
  required property var list

  implicitHeight: Style.launcher.itemHeight

  anchors.left: parent?.left
  anchors.right: parent?.right

  signal clicked

  IStateLayer {
    radius: Settings.appearance.cornerRadius

    function onClicked(): void {
      root.modelData?.onClicked(root.list);
      root.clicked();
    }
  }

  Item {
    anchors.fill: parent
    anchors.leftMargin: Style.appearance.padding.small
    anchors.rightMargin: Style.appearance.padding.small
    anchors.margins: Style.appearance.padding.small

    IIcon {
      id: icon

      icon: root.modelData?.icon ?? ""
      pointSize: Style.appearance.font.size.extraLarge

      anchors.verticalCenter: parent.verticalCenter
    }

    Item {
      anchors.left: icon.right
      anchors.leftMargin: Style.appearance.padding.small
      anchors.verticalCenter: icon.verticalCenter

      implicitWidth: parent.width - icon.width
      implicitHeight: name.implicitHeight + desc.implicitHeight

      IText {
        id: name

        text: root.modelData?.name ?? ""
        pointSize: Style.appearance.font.size.larger
      }

      IText {
        id: desc

        text: root.modelData?.desc ?? ""
        pointSize: Style.appearance.font.size.smaller
        color: ThemeService.palette.mOutline

        elide: Text.ElideRight
        width: root.width - icon.width - Style.appearance.padding.small * 2

        anchors.top: name.bottom
      }
    }
  }
}
