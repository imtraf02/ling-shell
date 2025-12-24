import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.services
import "../extras"

Item {
  id: root

  property ShellScreen screen

  readonly property int warningThreshold: 30

  readonly property var battery: UPower.displayDevice
  readonly property bool isReady: battery && battery.ready && battery.isLaptopBattery && battery.isPresent
  readonly property real percent: isReady ? (battery.percentage * 100) : 0
  readonly property bool charging: isReady ? battery.state === UPowerDeviceState.Charging : false
  readonly property bool pluggedIn: isReady ? ![UPowerDeviceState.Discharging, UPowerDeviceState.Empty].includes(battery.state) : false
  property bool hasNotifiedLowBattery: false

  implicitWidth: pill.width
  implicitHeight: pill.height

  function maybeNotify(percent, charging) {
    if (!charging && !root.hasNotifiedLowBattery && percent <= warningThreshold) {
      root.hasNotifiedLowBattery = true;
    } else if (root.hasNotifiedLowBattery && (charging || percent > warningThreshold + 5)) {
      root.hasNotifiedLowBattery = false;
    }
  }

  Connections {
    target: UPower.displayDevice
    function onPercentageChanged() {
      const currentPercent = UPower.displayDevice.percentage * 100;
      const isCharging = UPower.displayDevice.state === UPowerDeviceState.Charging;
      root.maybeNotify(currentPercent, isCharging);
    }

    function onStateChanged() {
      const isCharging = UPower.displayDevice.state === UPowerDeviceState.Charging;
      const isPluggedIn = ![UPowerDeviceState.Discharging, UPowerDeviceState.Empty].includes(UPower.displayDevice.state);
      if (isCharging || isPluggedIn) {
        root.hasNotifiedLowBattery = false;
      }
      const currentPercent = UPower.displayDevice.percentage * 100;
      root.maybeNotify(currentPercent, isCharging);
    }
  }

  BarPill {
    id: pill
    icon: BatteryService.getIcon(root.percent, root.charging || root.pluggedIn, root.isReady)
    text: Math.round(root.percent)
    suffix: "%"

    onClicked: {
      VisibilityService.getPanel("battery", root.screen)?.toggle(this);
    }
  }
}
