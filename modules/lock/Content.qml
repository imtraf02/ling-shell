import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.services

RowLayout {
  id: root

  required property WlSessionLockSurface lock

  spacing: Style.spacing.small

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.spacing.small

    ClippingRectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      topLeftRadius: Style.rounding.large
      radius: Style.rounding.small
      color: ThemeService.palette.mSurfaceContainer

      Fetch {}
    }

    ClippingRectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: resources.implicitHeight

      radius: Style.rounding.small
      color: ThemeService.palette.mSurfaceContainer

      Resources {
        id: resources
      }
    }

    ClippingRectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: media.implicitHeight

      bottomLeftRadius: Style.rounding.large
      radius: Style.rounding.small
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
    spacing: Style.spacing.small

    ClippingRectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true

      topRightRadius: Style.rounding.large
      radius: Style.rounding.small
      color: ThemeService.palette.mSurfaceContainer

      NotifDock {
        id: notifications
      }
    }

    ClippingRectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: powerMenu.implicitHeight

      bottomRightRadius: Style.rounding.large
      radius: Style.rounding.small
      color: ThemeService.palette.mSurfaceContainer

      PowerMenu {
        id: powerMenu
      }
    }
  }
}
