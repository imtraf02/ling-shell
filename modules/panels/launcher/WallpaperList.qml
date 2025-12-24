pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.commons
import qs.widgets
import qs.services
import "../../../helpers/fuzzysort.js" as Fuzzysort

Item {
  id: root
  required property var panel
  required property ITextInput searchInput

  property int currentScreenIndex: {
    if (panel.screen !== null) {
      for (var i = 0; i < Quickshell.screens.length; i++) {
        if (Quickshell.screens[i].name === panel.screen.name)
          return i;
      }
    }
    return 0;
  }
  property var currentScreen: Quickshell.screens[currentScreenIndex]

  implicitWidth: Math.max(Config.launcher.sizes.itemWidth * 1.2, list.implicitWidth)
  implicitHeight: content.height

  function incrementCurrentIndex() {
    let currentView = screenRepeater.itemAt(currentScreenIndex);
    if (currentView?.item) {
      currentView.item.incrementCurrentIndex();
    }
  }

  function decrementCurrentIndex() {
    let currentView = screenRepeater.itemAt(currentScreenIndex);
    if (currentView?.item) {
      currentView.item.decrementCurrentIndex();
    }
  }

  function updateWallpaper() {
    let currentView = screenRepeater.itemAt(currentScreenIndex);
    if (currentView?.item) {
      const pathView = currentView.item;
      const currentItem = pathView.currentItem;

      if (currentItem && currentItem.wallpaperPath) {
        WallpaperService.changeWallpaper(currentItem.wallpaperPath, pathView.targetScreen.name);
      }
    }
  }

  ColumnLayout {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right

    RowLayout {
      id: header
      Layout.fillWidth: true
      spacing: Config.appearance.spacing.small

      IIcon {
        icon: "image"
        pointSize: Config.appearance.widget.size * 0.8
        color: ThemeService.palette.mPrimary
      }

      IText {
        text: "Wallpaper selector"
        color: ThemeService.palette.mOnSurface
        Layout.fillWidth: true
      }

      IIconButton {
        icon: "refresh"
        size: Config.appearance.widget.size * 0.8
        onClicked: {
          WallpaperService.refreshWallpapersList();
        }
      }
    }

    IDivider {
      Layout.fillWidth: true
    }

    IToggle {
      label: "Apply to all monitors"
      description: "Apply selected wallpaper to all monitors at once."
      checked: Settings.wallpaper.setWallpaperOnAllMonitors
      onToggled: checked => Settings.wallpaper.setWallpaperOnAllMonitors = checked
      Layout.fillWidth: true
    }

    ITabBar {
      id: screenTabBar
      visible: !Settings.wallpaper.setWallpaperOnAllMonitors || Settings.wallpaper.enableMultiMonitorDirectories
      Layout.fillWidth: true
      currentIndex: root.currentScreenIndex
      onCurrentIndexChanged: root.currentScreenIndex = currentIndex
      spacing: Config.appearance.spacing.small

      Repeater {
        model: Quickshell.screens
        ITabButton {
          required property var modelData
          required property int index
          text: modelData.name || `Screen ${index + 1}`
          tabIndex: index
          checked: screenTabBar.currentIndex === index
        }
      }
    }

    Item {
      id: list
      Layout.fillWidth: true
      Layout.preferredHeight: Config.launcher.sizes.wallpaperHeight

      Repeater {
        id: screenRepeater
        model: Quickshell.screens

        delegate: Loader {
          id: loaderDelegate

          required property int index
          required property var modelData

          anchors.fill: parent
          active: index === root.currentScreenIndex

          sourceComponent: WallpaperScreenView {
            targetScreen: loaderDelegate.modelData
          }

          onImplicitWidthChanged: {
            if (loaderDelegate.index === root.currentScreenIndex) {
              list.implicitWidth = implicitWidth;
            }
          }
        }
      }
    }
  }

  component WallpaperScreenView: PathView {
    id: pathView
    property ShellScreen targetScreen
    property var wallpapersList: []
    property string currentWallpaper: ""

    readonly property int itemWidth: Config.launcher.sizes.wallpaperWidth * 0.8 + Config.appearance.padding.larger * 2
    readonly property int numItems: {
      if (!targetScreen)
        return 0;

      const maxWidth = targetScreen.width - Settings.appearance.thickness * 4;
      if (maxWidth <= 0)
        return 0;
      const maxItemsOnScreen = Math.floor(maxWidth / itemWidth);
      const visible = Math.min(maxItemsOnScreen, Config.launcher.maxWallpapers, scriptModel.values.length);
      if (visible === 2)
        return 1;
      if (visible > 1 && visible % 2 === 0)
        return visible - 1;
      return visible;
    }

    Component.onCompleted: {
      wallpapersList = WallpaperService.getWallpapersList(targetScreen.name);
      currentWallpaper = WallpaperService.getWallpaper(targetScreen.name);
      currentIndex = wallpapersList.indexOf(currentWallpaper);
    }

    Connections {
      target: root.searchInput.inputItem

      function onTextChanged() {
        const filter = root.searchInput.inputItem.text.split(" ").slice(1).join(" ");

        if (!filter) {
          scriptModel.values = pathView.wallpapersList;
        } else {
          const wallpapersWithNames = pathView.wallpapersList.map(p => ({
                path: p,
                name: p.split('/').pop()
              }));
          const results = Fuzzysort.go(filter, wallpapersWithNames, {
            key: 'name'
          });
          scriptModel.values = results.map(r => r.obj.path);
        }

        pathView.currentIndex = scriptModel.values.findIndex(w => w === pathView.currentWallpaper);
      }
    }

    Connections {
      target: WallpaperService

      function onWallpaperChanged(screenName, path) {
        if (pathView.targetScreen && screenName === pathView.targetScreen.name) {
          pathView.currentWallpaper = WallpaperService.getWallpaper(pathView.targetScreen.name);
        }
      }

      function onWallpaperDirectoryChanged(screenName, directory) {
        if (pathView.targetScreen && screenName === pathView.targetScreen.name) {
          pathView.wallpapersList = WallpaperService.getWallpapersList(pathView.targetScreen.name);
          pathView.currentWallpaper = WallpaperService.getWallpaper(pathView.targetScreen.name);
          pathView.currentIndex = pathView.wallpapersList.indexOf(pathView.currentWallpaper);
        }
      }

      function onWallpaperListChanged(screenName, count) {
        if (pathView.targetScreen && screenName === pathView.targetScreen.name) {
          pathView.wallpapersList = WallpaperService.getWallpapersList(pathView.targetScreen.name);
          pathView.currentWallpaper = WallpaperService.getWallpaper(pathView.targetScreen.name);
          pathView.currentIndex = pathView.wallpapersList.indexOf(pathView.currentWallpaper);
        }
      }
    }

    implicitWidth: Math.min(numItems, count) * itemWidth
    pathItemCount: numItems
    cacheItemCount: 4

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    MouseArea {
      anchors.fill: parent
      propagateComposedEvents: true
      acceptedButtons: Qt.NoButton

      onWheel: wheel => {
        if (wheel.angleDelta.y > 0) {
          pathView.decrementCurrentIndex();
        } else if (wheel.angleDelta.y < 0) {
          pathView.incrementCurrentIndex();
        }
        wheel.accepted = true;
      }
    }

    model: ScriptModel {
      id: scriptModel
      values: pathView.wallpapersList

      onValuesChanged: {
        for (var i = 0; i < values.length; i++) {
          if (scriptModel.values[i] === pathView.currentWallpaper) {
            pathView.currentIndex = i;
            return;
          }
        }
        pathView.currentIndex = 0;
      }
    }

    delegate: Item {
      id: delegateItem

      required property int index
      required property string modelData

      property string wallpaperPath: modelData
      property bool isSelected: wallpaperPath === pathView.currentWallpaper
      property string filename: wallpaperPath.split('/').pop()

      z: PathView.isCurrentItem ? 1 : 0
      scale: PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0.5
      opacity: PathView.onPath ? 1 : 0
      implicitWidth: image.width + Config.appearance.padding.larger * 2
      implicitHeight: image.height + label.height + Config.appearance.padding.larger * 2

      IStateLayer {
        radius: Settings.appearance.cornerRadius

        function onClicked() {
          WallpaperService.changeWallpaper(delegateItem.wallpaperPath, pathView.targetScreen.name);
          pathView.currentIndex = delegateItem.index;
        }
      }

      IElevation {
        anchors.fill: image
        radius: image.radius
        opacity: pathView.currentIndex === delegateItem.index ? 1 : 0
        level: 4

        Behavior on opacity {
          IAnim {}
        }
      }

      IIcon {
        anchors.centerIn: parent
        icon: "image"
        color: ThemeService.palette.mOutline
      }

      ClippingRectangle {
        id: image
        anchors.horizontalCenter: parent.horizontalCenter
        y: Config.appearance.padding.larger
        color: delegateItem.isSelected ? ThemeService.palette.mPrimary : ThemeService.palette.mSurfaceVariant
        implicitWidth: Config.launcher.sizes.wallpaperWidth
        implicitHeight: implicitWidth / 16 * 9
        radius: Settings.appearance.cornerRadius

        IImageCached {
          maxCacheDimension: 384
          imagePath: delegateItem.wallpaperPath
          cacheFolder: Directories.shellCacheWallpaperDir
          anchors.fill: parent
        }
      }

      IText {
        id: label
        anchors.top: image.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        text: delegateItem.filename
      }

      Behavior on scale {
        NumberAnimation {
          duration: 200
          easing.type: Easing.OutCubic
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: 200
          easing.type: Easing.OutCubic
        }
      }
    }

    path: Path {
      startY: pathView.height / 2

      PathAttribute {
        name: "z"
        value: 0
      }
      PathLine {
        x: pathView.width / 2
        relativeY: 0
      }
      PathAttribute {
        name: "z"
        value: 1
      }
      PathLine {
        x: pathView.width
        relativeY: 0
      }
    }
  }
}
