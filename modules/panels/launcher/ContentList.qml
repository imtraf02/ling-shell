pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

Item {
  id: root

  required property var panel
  required property ITextInput searchInput
  required property int padding

  required property real maxHeight

  readonly property bool showWallpapers: searchInput.inputItem.text.startsWith(`${Config.launcher.actionPrefix}wallpaper `)
  readonly property var currentList: showWallpapers ? wallpaperList.item : appList.item

  anchors.horizontalCenter: parent.horizontalCenter
  anchors.bottom: parent.bottom

  clip: true

  state: showWallpapers ? "wallpapers" : "apps"

  states: [
    State {
      name: "apps"

      PropertyChanges {
        root.implicitWidth: Config.launcher.sizes.itemWidth
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
    }
  ]

  Behavior on state {
    SequentialAnimation {
      IAnim {
        target: root
        property: "opacity"
        from: 1
        to: 0
        duration: Config.appearance.anim.durations.small
      }
      PropertyAction {}
      IAnim {
        target: root
        property: "opacity"
        from: 0
        to: 1
        duration: Config.appearance.anim.durations.small
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

    spacing: Config.appearance.spacing.small
    padding: Config.appearance.padding.larger

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    IIcon {
      icon: root.state === "wallpapers" ? "wallpaper_slideshow" : "manage_search"
      color: ThemeService.palette.mOnSurfaceVariant
      pointSize: Config.appearance.font.size.extraLarge

      anchors.verticalCenter: parent.verticalCenter
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter

      IText {
        text: root.state === "wallpapers" ? "No wallpapers found" : "No results"
        color: ThemeService.palette.mOnSurfaceVariant
        pointSize: Config.appearance.font.size.large
      }

      IText {
        text: "Try searching for something else"
        color: ThemeService.palette.mOnSurfaceVariant
        pointSize: Config.appearance.font.size.normal
      }
    }

    Behavior on opacity {
      IAnim {}
    }

    Behavior on scale {
      IAnim {}
    }
  }

  Behavior on implicitWidth {
    enabled: root.panel.shouldBeActive

    IAnim {
      duration: Config.appearance.anim.durations.large
      easing.bezierCurve: Config.appearance.anim.curves.emphasizedDecel
    }
  }

  Behavior on implicitHeight {
    enabled: root.panel.shouldBeActive

    IAnim {
      duration: Config.appearance.anim.durations.large
      easing.bezierCurve: Config.appearance.anim.curves.emphasizedDecel
    }
  }
}
