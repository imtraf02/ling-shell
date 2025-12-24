pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.config
import qs.commons
import qs.services
import qs.widgets

ColumnLayout {
  id: root

  readonly property real padding: Config.appearance.padding.normal
  readonly property real spacing: Config.appearance.spacing.small

  anchors.fill: parent
  anchors.margins: padding

  RowLayout {
    Layout.fillWidth: true
    Layout.fillHeight: false
    spacing: Config.appearance.spacing.normal

    Rectangle {
      implicitWidth: prompt.implicitWidth + root.padding * 2
      implicitHeight: prompt.implicitHeight + root.padding * 2

      color: ThemeService.palette.mPrimary
      radius: Settings.appearance.cornerRadius

      MonoText {
        id: prompt

        anchors.centerIn: parent
        text: ">"
        font.pointSize: root.width > 400 ? Config.appearance.font.size.larger : Config.appearance.font.size.normal
        color: ThemeService.palette.mOnPrimary
      }
    }

    MonoText {
      Layout.fillWidth: true
      text: "LingShell"
      font.pointSize: root.width > 400 ? Config.appearance.font.size.larger : Config.appearance.font.size.normal
      elide: Text.ElideRight
    }
  }

  RowLayout {
    Layout.fillWidth: true
    Layout.fillHeight: false
    spacing: height * 0.15

    OsLogo {
      Layout.fillHeight: true
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.topMargin: root.padding
      Layout.bottomMargin: root.padding
      spacing: Config.appearance.spacing.normal

      FetchText {
        text: "OS: " + DistroService.osPretty
      }

      FetchText {
        text: "WM: " + DistroService.wm
      }

      FetchText {
        text: "USER: " + DistroService.user
      }

      FetchText {
        text: "UP: " + DistroService.uptime
      }

      FetchText {
        visible: UPower.displayDevice.isLaptopBattery
        text: `BATT: ${UPower.onBattery ? "" : "(+) "}${Math.round(UPower.displayDevice.percentage * 100)}%`
      }
    }
  }

  component OsLogo: IColouredIcon {
    id: iconImage
    source: DistroService.osLogo
    implicitSize: height
    asynchronous: true
    colour: ThemeService.palette.mPrimary
  }

  component FetchText: MonoText {
    Layout.fillWidth: true
    font.pointSize: root.width > 400 ? Config.appearance.font.size.larger : Config.appearance.font.size.normal
    elide: Text.ElideRight
  }

  component MonoText: IText {
    font.family: Config.appearance.font.family.mono
  }
}
