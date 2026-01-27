import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

RowLayout {
  id: root

  spacing: Style.spacing.small

  anchors.left: parent.left
  anchors.right: parent.right
  anchors.margins: Style.padding.normal

  Resource {
    icon: "memory"
    value: SystemUsageService.cpuUsage
    colour: ThemeService.palette.mPrimary
  }

  Resource {
    icon: "thermostat"
    value: SystemUsageService.cpuTemp
    colour: ThemeService.palette.mSecondary
  }

  Resource {
    icon: "memory_alt"
    value: SystemUsageService.memPercent
    colour: ThemeService.palette.mSecondary
  }

  Resource {
    icon: "hard_disk"
    value: SystemUsageService.diskPercents["/"] ?? 0
    colour: ThemeService.palette.mTertiary
  }

  component Resource: Rectangle {
    id: res
    required property string icon
    required property real value
    required property color colour

    Layout.fillWidth: true
    Layout.preferredHeight: stat.height + Style.padding.normal * 2

    color: ThemeService.palette.mSurfaceContainer
    radius: Style.rounding.small

    ICircleStat {
      id: stat
      anchors.centerIn: parent
      implicitHeight: 40
      value: parent.value
      icon: parent.icon
      flat: true
      circleColor: parent.colour
      // circleWidth: 6
      // iconSize: Style.font.size.extraLarge
      // valueFontSize: Style.font.size.large
    }
  }
}
