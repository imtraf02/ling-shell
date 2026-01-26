pragma ComponentBehavior: Bound

import QtQuick
import qs.common
import qs.widgets
import qs.modules.panels
import qs.modules.panels.launcher.services

SmartPanel {
  id: root

  position: "bottom"
  anchor: "center"

  readonly property real maxHeight: {
    let max = screen.height - Settings.appearance.thickness * 2 - Style.padding.large;
    return max;
  }

  panelContent: Item {
    property real contentPreferredWidth: listWrapper.width + Style.padding.small * 2
    property real contentPreferredHeight: searchInput.height + listWrapper.height + Style.padding.small * 2

    Item {
      id: listWrapper

      implicitWidth: list.width
      implicitHeight: list.height + Style.padding.small

      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: searchInput.top
      anchors.bottomMargin: Style.padding.small

      Content {
        id: list

        panel: root
        searchInput: searchInput
        maxHeight: root.maxHeight - searchInput.implicitHeight - Style.padding.small * 3
      }
    }

    ITextInput {
      id: searchInput
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: Style.padding.small

      fontSize: Style.font.size.larger

      placeholderText: `Type \"${Settings.launcher.actionPrefix}\" for commands`

      onAccepted: {
        if (list.showWallpapers) {
          list.currentList?.updateWallpaper();
        } else {
          const currentItem = list.currentList?.currentItem;
          if (currentItem) {
            if (inputItem.text.startsWith(Settings.launcher.actionPrefix)) {
              currentItem.modelData.onClicked(list.currentList);
            } else {
              AppsService.launch(currentItem.modelData);
              root.close();
            }
          }
        }
      }

      Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
      Keys.onDownPressed: list.currentList?.incrementCurrentIndex()
      Keys.onEscapePressed: root.close()

      Component.onCompleted: {
        if (searchInput.inputItem) {
          searchInput.inputItem.forceActiveFocus();
        }
      }
    }
  }
}
