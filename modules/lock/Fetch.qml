pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.common
import qs.services
import qs.widgets

ColumnLayout {
  id: root
  anchors.fill: parent
  anchors.margins: Style.padding.normal

  RowLayout {
    Layout.fillWidth: true
    Layout.fillHeight: false
    spacing: Style.spacing.small

    OsLogo {
      Layout.fillHeight: true
    }

    MonoText {
      Layout.fillWidth: true
      text: "LingShell"
      font.pointSize: Style.font.size.larger
      font.weight: Font.Medium
      elide: Text.ElideRight
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    Layout.topMargin: Style.padding.small
    Layout.bottomMargin: Style.padding.small
    spacing: Style.spacing.small

    FetchText {
      text: "○ OS: " + DistroService.osPretty
    }
    FetchText {
      text: "□ WM: " + DistroService.wm
    }
    FetchText {
      text: "◇ USER: " + DistroService.user
    }
    FetchText {
      text: "△ UP: " + DistroService.uptime
    }
    FetchText {
      visible: UPower.displayDevice.isLaptopBattery
      text: `◈ BATT: ${UPower.onBattery ? "" : "(+) "}${Math.round(UPower.displayDevice.percentage * 100)}%`
    }
  }

  RowLayout {
    spacing: Style.spacing.large

    Repeater {
      model: [ThemeService.palette.mPrimary, ThemeService.palette.mSecondary, ThemeService.palette.mTertiary, ThemeService.palette.mSurface]

      Rectangle {
        required property color modelData

        implicitWidth: implicitHeight
        implicitHeight: Style.font.size.larger * 2
        color: modelData
        radius: Style.rounding.full
      }
    }
  }

  component OsLogo: IColouredIcon {
    source: DistroService.osLogo
    implicitSize: height
    asynchronous: true
    colour: ThemeService.palette.mPrimary
  }

  component FetchText: MonoText {
    Layout.fillWidth: true
    font.pointSize: Style.font.size.normal
    elide: Text.ElideRight
  }

  component MonoText: IText {
    font.family: Settings.appearance.font.mono
  }
}
