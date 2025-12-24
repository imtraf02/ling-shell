import QtQuick
import QtQuick.Layouts
import qs.config
import qs.commons
import qs.services
import qs.widgets

RowLayout {
  id: root

  spacing: Config.appearance.spacing.small

  anchors.left: parent.left
  anchors.right: parent.right
  anchors.margins: Config.appearance.padding.normal

  Resource {
    icon: "memory"
    value: SystemStatService.cpuUsage
    colour: ThemeService.palette.mPrimary
  }

  Resource {
    icon: "thermostat"
    value: SystemStatService.cpuTemp
    colour: ThemeService.palette.mSecondary
  }

  Resource {
    icon: "memory_alt"
    value: SystemStatService.memPercent
    colour: ThemeService.palette.mSecondary
  }

  Resource {
    icon: "hard_disk"
    value: SystemStatService.diskPercents["/"] ?? 0
    colour: ThemeService.palette.mTertiary
  }

  component Resource: Rectangle {
    id: res
    required property string icon
    required property real value
    required property color colour

    Layout.fillWidth: true
    Layout.preferredHeight: stat.height + Config.appearance.padding.normal * 2

    color: ThemeService.palette.mSurfaceContainer
    radius: Settings.appearance.cornerRadius

    ICircleStat {
      id: stat
      anchors.centerIn: parent
      implicitHeight: 40
      value: parent.value
      icon: parent.icon
      flat: true
      circleColor: parent.colour
      // circleWidth: 6
      // iconSize: Config.appearance.font.size.extraLarge
      // valueFontSize: Config.appearance.font.size.large
    }
  }
}
