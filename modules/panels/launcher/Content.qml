pragma ComponentBehavior: Bound

import QtQuick
import qs.common
import qs.services
import qs.widgets

Item {
  id: root

  required property var panel
  required property ITextInput searchInput

  required property real maxHeight

  readonly property bool showWallpapers: searchInput.inputItem.text.startsWith(`${Settings.launcher.actionPrefix}wallpaper `)
  readonly property bool showLiveWallpapers: searchInput.inputItem.text.startsWith(`${Settings.launcher.actionPrefix}live-wallpaper `)
  readonly property var currentList: showWallpapers ? wallpaperList.item : (showLiveWallpapers ? liveWallpaperList.item : appList.item)

  anchors.horizontalCenter: parent.horizontalCenter
  anchors.bottom: parent.bottom

  clip: true

  state: showWallpapers ? "wallpapers" : (showLiveWallpapers ? "live-wallpapers" : "apps")

  states: [
    State {
      name: "apps"

      PropertyChanges {
        root.implicitWidth: Style.launcher.itemWidth
        root.implicitHeight: Math.min(root.maxHeight, appList.implicitHeight > 0 ? appList.implicitHeight : empty.implicitHeight)
        appList.active: true
      }

      AnchorChanges {
        anchors.left: root.parent.left
        anchors.right: root.parent.right
      }
    },
    State {
      name: "wallpapers"

      PropertyChanges {
        root.implicitWidth: wallpaperList.implicitWidth
        root.implicitHeight: wallpaperList.implicitHeight
        wallpaperList.active: true
      }
    },
    State {
      name: "live-wallpapers"

      PropertyChanges {
        root.implicitWidth: liveWallpaperList.implicitWidth
        root.implicitHeight: liveWallpaperList.implicitHeight
        liveWallpaperList.active: true
      }
    }
  ]

  Behavior on state {
    SequentialAnimation {
      IAnim {
        target: root
        property: "opacity"
        from: 1
        to: 0
        duration: Style.anim.durations.small
      }
      PropertyAction {}
      IAnim {
        target: root
        property: "opacity"
        from: 0
        to: 1
        duration: Style.anim.durations.small
      }
    }
  }

  Loader {
    id: appList

    active: false

    anchors.fill: parent

    sourceComponent: AppList {
      searchInput: root.searchInput
      panel: root.panel
    }
  }

  Loader {
    id: liveWallpaperList
    active: false
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    sourceComponent: WallpaperList {
      searchInput: root.searchInput
      panel: root.panel
      liveMode: true
    }
  }

  Loader {
    id: wallpaperList

    active: false

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter

    sourceComponent: WallpaperList {
      searchInput: root.searchInput
      panel: root.panel
    }
  }

  Row {
    id: empty

    opacity: root.currentList?.count === 0 ? 1 : 0
    scale: root.currentList?.count === 0 ? 1 : 0.5

    spacing: Style.spacing.small
    padding: Style.padding.larger

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    IIcon {
      icon: root.state === "apps" ? "manage_search" : (root.state === "live-wallpapers" ? "movie" : "wallpaper_slideshow")
      color: ThemeService.palette.mOnSurfaceVariant
      font.pointSize: Style.font.size.extraLarge

      anchors.verticalCenter: parent.verticalCenter
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter

      IText {
        text: root.state === "apps" ? "No results" : (root.state === "live-wallpapers" ? "No live wallpapers found" : "No wallpapers found")
        color: ThemeService.palette.mOnSurfaceVariant
        font.pointSize: Style.font.size.large
      }

      IText {
        text: "Try searching for something else"
        color: ThemeService.palette.mOnSurfaceVariant
        font.pointSize: Style.font.size.normal
      }
    }

    Behavior on opacity {
      IAnim {}
    }

    Behavior on scale {
      IAnim {}
    }
  }
}
