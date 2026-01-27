pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.services

Popup {
  id: root

  property alias model: listView.model
  property real itemHeight: 36
  property real itemPadding: Style.padding.normal

  signal triggered(string action)

  width: 180
  padding: Style.padding.normal

  background: Rectangle {
    color: ThemeService.palette.mSurface
    border.color: ThemeService.palette.mOutline
    border.width: 1
    radius: Style.rounding.small
  }

  contentItem: IListView {
    id: listView

    implicitHeight: contentHeight
    spacing: Style.spacing.small
    interactive: contentHeight > root.height

    IScrollBar.vertical: IScrollBar {
      flickable: listView
    }

    delegate: ItemDelegate {
      id: menuItem

      required property int index
      required property var modelData

      width: listView.width
      height: modelData.visible !== false ? root.itemHeight : 0
      visible: modelData.visible !== false
      opacity: modelData.enabled !== false ? 1 : 0.5
      enabled: modelData.enabled !== false

      property Popup popup: root

      background: Rectangle {
        color: menuItem.hovered && menuItem.enabled ? ThemeService.palette.mPrimary : ThemeService.palette.mSurfaceContainer

        radius: Style.rounding.small

        Behavior on color {
          ICAnim {}
        }
      }

      contentItem: RowLayout {
        spacing: Style.spacing.small

        IIcon {
          visible: menuItem.modelData.icon !== undefined
          icon: menuItem.modelData.icon || ""
          font.pointSize: Style.font.size.normal
          color: menuItem.hovered && menuItem.enabled ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface

          Layout.leftMargin: root.itemPadding

          Behavior on color {
            ICAnim {}
          }
        }

        IText {
          text: menuItem.modelData.label || menuItem.modelData.text || ""
          font.pointSize: Style.font.size.normal
          color: menuItem.hovered && menuItem.enabled ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface

          verticalAlignment: Text.AlignVCenter
          Layout.fillWidth: true
          Layout.leftMargin: menuItem.modelData.icon === undefined ? root.itemPadding : 0

          Behavior on color {
            ICAnim {}
          }
        }
      }

      onClicked: {
        if (enabled) {
          root.triggered(menuItem.modelData.action || menuItem.modelData.key || menuItem.index.toString());
          popup.close();
        }
      }
    }
  }

  function openAt(x, y) {
    root.x = x;
    root.y = y;
    root.open();
  }

  function openAtItem(item, mouseX, mouseY) {
    var pos = item.mapToItem(root.parent, mouseX || 0, mouseY || 0);
    openAt(pos.x, pos.y);
  }
}
