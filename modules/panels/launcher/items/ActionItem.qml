import QtQuick
import qs.common
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
    anchors.leftMargin: Style.padding.small
    anchors.rightMargin: Style.padding.small
    anchors.margins: Style.padding.small

    IIcon {
      id: icon

      icon: root.modelData?.icon ?? ""
      font.pointSize: Style.font.size.extraLarge

      anchors.verticalCenter: parent.verticalCenter
    }

    Item {
      anchors.left: icon.right
      anchors.leftMargin: Style.padding.small
      anchors.verticalCenter: icon.verticalCenter

      implicitWidth: parent.width - icon.width
      implicitHeight: name.implicitHeight + desc.implicitHeight

      IText {
        id: name

        text: root.modelData?.name ?? ""
        font.pointSize: Style.font.size.larger
      }

      IText {
        id: desc

        text: root.modelData?.desc ?? ""
        font.pointSize: Style.font.size.smaller
        color: ThemeService.palette.mOutline

        elide: Text.ElideRight
        width: root.width - icon.width - Style.padding.small * 2

        anchors.top: name.bottom
      }
    }
  }
}
