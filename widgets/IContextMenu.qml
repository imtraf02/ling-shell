pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.commons
import qs.services

Popup {
  id: root

  property alias model: listView.model
  property real itemHeight: 36
  property real itemPadding: Config.appearance.padding.normal

  signal triggered(string action)

  width: 180
  padding: Config.appearance.padding.normal

  onOpened: VisibilityService.willOpenPopup(root)
  onClosed: VisibilityService.willClosePopup(root)

  background: Rectangle {
    color: ThemeService.palette.mSurface
    border.color: ThemeService.palette.mOutline
    border.width: 1
    radius: Settings.appearance.cornerRadius
  }

  contentItem: IListView {
    id: listView

    implicitHeight: contentHeight
    spacing: Config.appearance.spacing.small
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
        radius: Settings.appearance.cornerRadius

        Behavior on color {
          ICAnim {}
        }
      }

      contentItem: RowLayout {
        spacing: Config.appearance.spacing.small

        IIcon {
          visible: menuItem.modelData.icon !== undefined
          icon: menuItem.modelData.icon || ""
          pointSize: Config.appearance.font.size.normal
          color: menuItem.hovered && menuItem.enabled ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface
          Layout.leftMargin: root.itemPadding

          Behavior on color {
            ICAnim {}
          }
        }

        IText {
          text: menuItem.modelData.label || menuItem.modelData.text || ""
          pointSize: Config.appearance.font.size.normal
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
