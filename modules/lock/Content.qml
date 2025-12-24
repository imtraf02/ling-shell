import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import qs.config
import qs.commons
import qs.services

RowLayout {
  id: root

  required property WlSessionLockSurface lock

  spacing: Config.appearance.spacing.small

  ColumnLayout {
    Layout.fillWidth: true
    spacing: root.spacing

    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      topLeftRadius: Settings.appearance.cornerRadius
      radius: Settings.appearance.cornerRadius
      color: ThemeService.palette.mSurfaceContainer

      Fetch {}
    }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: media.implicitHeight

      bottomLeftRadius: Config.appearance.rounding.large
      radius: Settings.appearance.cornerRadius
      color: ThemeService.palette.mSurfaceContainer

      Media {
        id: media
      }
    }
  }

  Center {
    lock: root.lock
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: root.spacing

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: resources.implicitHeight

      topRightRadius: Settings.appearance.cornerRadius
      radius: Settings.appearance.cornerRadius
      color: ThemeService.palette.mSurfaceContainer

      Resources {
        id: resources
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true

      radius: Settings.appearance.cornerRadius
      color: ThemeService.palette.mSurfaceContainer

      NotifDock {
        id: notifications
      }
    }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: powerMenu.implicitHeight

      bottomRightRadius: Settings.appearance.cornerRadius
      radius: Settings.appearance.cornerRadius
      color: ThemeService.palette.mSurfaceContainer

      PowerMenu {
        id: powerMenu
      }
    }
  }
}
