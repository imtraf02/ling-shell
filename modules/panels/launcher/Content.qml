pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.widgets
import qs.modules.panels.launcher.services

Item {
  id: root

  required property var panel
  required property real maxHeight

  readonly property real padding: Config.appearance.padding.normal
  readonly property real spacing: Config.appearance.spacing.small

  implicitWidth: listWrapper.width + padding * 2
  implicitHeight: searchInput.height + listWrapper.height + padding * 2

  Item {
    id: listWrapper

    implicitWidth: list.width
    implicitHeight: list.height + root.padding

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: searchInput.top
    anchors.bottomMargin: root.padding

    ContentList {
      id: list

      panel: root.panel
      searchInput: searchInput
      padding: root.padding
      maxHeight: root.maxHeight - searchInput.implicitHeight - root.padding * 3
    }
  }

  ITextInput {
    id: searchInput
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: root.padding

    fontSize: Config.appearance.font.size.larger
    fontWeight: Font.Medium

    placeholderText: `Type \"${Config.launcher.actionPrefix}\" for commands`

    onAccepted: {
      if (list.showWallpapers) {
        list.currentList?.updateWallpaper();
      } else {
        const currentItem = list.currentList?.currentItem;
        if (currentItem) {
          if (inputItem.text.startsWith(Config.launcher.actionPrefix)) {
            currentItem.modelData.onClicked(list.currentList);
          } else {
            AppsService.launch(currentItem.modelData);
            root.panel.close();
          }
        }
      }
    }

    Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
    Keys.onDownPressed: list.currentList?.incrementCurrentIndex()
    Keys.onEscapePressed: root.panel.close()

    Component.onCompleted: {
      if (searchInput.inputItem) {
        searchInput.inputItem.forceActiveFocus();
      }
    }
  }
}
