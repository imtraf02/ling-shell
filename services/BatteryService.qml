pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
  id: root

  function getIcon(percent, charging, isReady) {
    if (!isReady) {
      return "battery_android_frame_alert";
    }

    if (charging) {
      return "battery_android_frame_bolt";
    }

    if (percent >= 98)
      return "battery_android_frame_full";
    if (percent >= 85)
      return "battery_android_frame_6";
    if (percent >= 70)
      return "battery_android_frame_5";
    if (percent >= 55)
      return "battery_android_frame_4";
    if (percent >= 40)
      return "battery_android_frame_3";
    if (percent >= 25)
      return "battery_android_frame_2";
    return "battery_android_frame_1";
  }
}
