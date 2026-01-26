pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import "../helpers/bluetooth-utils.js" as BluetoothUtils

Singleton {
  id: root

  readonly property var categoryIcons: ({
      WebBrowser: "web",
      Printing: "print",
      Security: "security",
      Network: "chat",
      Archiving: "archive",
      Compression: "archive",
      Development: "code",
      IDE: "code",
      TextEditor: "edit_note",
      Audio: "music_note",
      Music: "music_note",
      Player: "music_note",
      Recorder: "mic",
      Game: "sports_esports",
      FileTools: "files",
      FileManager: "files",
      Filesystem: "files",
      FileTransfer: "files",
      Settings: "settings",
      DesktopSettings: "settings",
      HardwareSettings: "settings",
      TerminalEmulator: "terminal",
      ConsoleOnly: "terminal",
      Utility: "build",
      Monitor: "monitor_heart",
      Midi: "graphic_eq",
      Mixer: "graphic_eq",
      AudioVideoEditing: "video_settings",
      AudioVideo: "music_video",
      Video: "videocam",
      Building: "construction",
      Graphics: "photo_library",
      "2DGraphics": "photo_library",
      RasterGraphics: "photo_library",
      TV: "tv",
      System: "host",
      Office: "content_paste"
    })

  function getAppCategoryIcon(name: string, fallback: string): string {
    const categories = DesktopEntries.heuristicLookup(name)?.categories;

    if (categories)
      for (const [key, value] of Object.entries(categoryIcons))
        if (categories.includes(key))
          return value;
    return fallback;
  }

  function getNotifIcon(summary: string, urgency: int): string {
    summary = summary.toLowerCase();
    if (summary.includes("reboot"))
      return "restart_alt";
    if (summary.includes("recording"))
      return "screen_record";
    if (summary.includes("battery"))
      return "power";
    if (summary.includes("screenshot"))
      return "screenshot_monitor";
    if (summary.includes("welcome"))
      return "waving_hand";
    if (summary.includes("time") || summary.includes("a break"))
      return "schedule";
    if (summary.includes("installed"))
      return "download";
    if (summary.includes("update"))
      return "update";
    if (summary.includes("unable to"))
      return "deployed_code_alert";
    if (summary.includes("profile"))
      return "person";
    if (summary.includes("file"))
      return "folder_copy";
    if (urgency === NotificationUrgency.Critical)
      return "release_alert";
    return "chat";
  }

  function getBrightnessIcon(level) {
    if (level >= 0.86)
      return "brightness_7";
    if (level >= 0.71)
      return "brightness_6";
    if (level >= 0.57)
      return "brightness_5";
    if (level >= 0.43)
      return "brightness_4";
    if (level >= 0.29)
      return "brightness_3";
    if (level >= 0.14)
      return "brightness_2";
    return "brightness_1";
  }

  function getBatteryIcon(percent, charging, isReady) {
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

  function getNetworkIcon(strength, isSecure = false) {
    if (isSecure) {
      if (strength >= 80)
        return "network_wifi_locked";
      if (strength >= 60)
        return "network_wifi_3_bar_locked";
      if (strength >= 40)
        return "network_wifi_2_bar_locked";
      if (strength >= 20)
        return "network_wifi_1_bar_locked";
      return "signal_wifi_0_bar";
    } else {
      if (strength >= 80)
        return "network_wifi";
      if (strength >= 60)
        return "network_wifi_3_bar";
      if (strength >= 40)
        return "network_wifi_2_bar";
      if (strength >= 20)
        return "network_wifi_1_bar";
      return "signal_wifi_0_bar";
    }
  }

  function getNetworkSignalStrengthLabel(signal) {
    if (signal >= 80)
      return "Excellent";
    if (signal >= 50)
      return "Good";
    if (signal >= 20)
      return "Fair";
    return "Poor";
  }

  function getBluetoothDeviceIcon(device) {
    if (!device) {
      return "bluetooth";
    }
    return BluetoothUtils.deviceIcon(device.name || device.deviceName, device.icon);
  }

  function getBluetoothSignalIcon(percent) {
    return BluetoothUtils.signalIcon(percent);
  }
}
