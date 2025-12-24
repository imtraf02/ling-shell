pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.config
import qs.commons
import qs.widgets
import qs.services
import ".."

BarPanel {
  id: root

  contentComponent: Item {
    id: content

    implicitWidth: Config.bar.sizes.batteryWidth
    implicitHeight: batteryBox.implicitHeight + (root.padding * 2)

    IBox {
      id: batteryBox
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: root.padding

      implicitHeight: batteryLayout.implicitHeight + batteryLayout.anchors.margins * 2

      ColumnLayout {
        id: batteryLayout
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: root.spacing

        IText {
          text: UPower.displayDevice.isLaptopBattery ? "Remaining: " + Math.round(UPower.displayDevice.percentage * 100) + "%" : "No battery detected"
        }

        IText {
          function formatSeconds(s: int, fallback: string): string {
            const day = Math.floor(s / 86400);
            const hr = Math.floor(s / 3600) % 60;
            const min = Math.floor(s / 60) % 60;

            let comps = [];
            if (day > 0)
              comps.push(`${day} days`);
            if (hr > 0)
              comps.push(`${hr} hours`);
            if (min > 0)
              comps.push(`${min} mins`);

            return comps.join(", ") || fallback;
          }

          text: UPower.displayDevice.isLaptopBattery ? ("Time " + (UPower.onBattery ? "remaining: " : "until charged: ") + (UPower.onBattery ? formatSeconds(UPower.displayDevice.timeToEmpty, "Calculating...") : formatSeconds(UPower.displayDevice.timeToFull, "Fully charged!"))) : ("Power profile: " + PowerProfile.toString(PowerProfiles.profile))
        }

        Loader {
          Layout.alignment: Qt.AlignHCenter
          active: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
          asynchronous: true
          Layout.preferredHeight: active ? (item?.implicitHeight ?? 0) : 0

          sourceComponent: Rectangle {
            implicitWidth: child.implicitWidth + root.padding * 2
            implicitHeight: child.implicitHeight + root.spacing * 2

            color: ThemeService.palette.mSurface
            border.color: ThemeService.palette.mError
            border.width: 1
            radius: Settings.appearance.cornerRadius

            Column {
              id: child
              anchors.centerIn: parent

              Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.spacing

                IIcon {
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.verticalCenterOffset: -font.pointSize / 10
                  icon: "warning"
                  color: ThemeService.palette.mError
                }

                IText {
                  text: "Performance Degraded"
                  color: ThemeService.palette.mError
                }

                IIcon {
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.verticalCenterOffset: -font.pointSize / 10
                  icon: "warning"
                  color: ThemeService.palette.mError
                }
              }

              IText {
                Layout.alignment: Qt.AlignHCenter
                text: `Reason: ${PerformanceDegradationReason.toString(PowerProfiles.degradationReason)}`
                color: ThemeService.palette.mError
              }
            }
          }
        }

        Rectangle {
          id: profiles

          property string current: {
            const p = PowerProfiles.profile;
            if (p === PowerProfile.PowerSaver)
              return saver.icon;
            if (p === PowerProfile.Performance)
              return perf.icon;
            return balance.icon;
          }

          Layout.alignment: Qt.AlignHCenter

          implicitWidth: saver.implicitHeight + balance.implicitHeight + perf.implicitHeight + root.spacing * 2 + root.padding * 2
          implicitHeight: Math.max(saver.implicitHeight, balance.implicitHeight, perf.implicitHeight) + root.spacing * 2

          color: ThemeService.palette.mSurface
          radius: Settings.appearance.cornerRadius

          Rectangle {
            id: indicator

            color: ThemeService.palette.mPrimary
            radius: Settings.appearance.cornerRadius
            state: parent.current

            states: [
              State {
                name: saver.icon
                Fill {
                  indicator: indicator
                  item: saver
                }
              },
              State {
                name: balance.icon
                Fill {
                  indicator: indicator
                  item: balance
                }
              },
              State {
                name: perf.icon
                Fill {
                  indicator: indicator
                  item: perf
                }
              }
            ]

            transitions: Transition {
              AnchorAnimation {
                duration: Config.appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.appearance.anim.curves.emphasized
              }
            }
          }

          Profile {
            id: saver
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: root.spacing
            profile: PowerProfile.PowerSaver
            icon: "energy_savings_leaf"
            current: parent.current
          }

          Profile {
            id: balance
            anchors.centerIn: parent
            profile: PowerProfile.Balanced
            icon: "balance"
            current: parent.current
          }

          Profile {
            id: perf
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: root.spacing
            profile: PowerProfile.Performance
            icon: "rocket_launch"
            current: parent.current
          }
        }
      }
    }
  }

  component Profile: Item {
    required property string icon
    required property int profile
    required property string current

    implicitWidth: icon.implicitHeight + root.spacing * 2
    implicitHeight: icon.implicitHeight + root.spacing * 2

    IIcon {
      id: icon
      anchors.centerIn: parent
      icon: parent.icon
      color: parent.current === text ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface
    }

    IStateLayer {
      radius: Settings.appearance.cornerRadius
      color: parent.current === parent.icon ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface

      function onClicked(): void {
        PowerProfiles.profile = parent.profile;
      }
    }
  }

  component Fill: AnchorChanges {
    required property Item item
    required property Rectangle indicator

    target: indicator
    anchors.left: item.left
    anchors.right: item.right
    anchors.top: item.top
    anchors.bottom: item.bottom
  }
}
