pragma Singleton

import Quickshell
import Quickshell.Services.Notifications

Singleton {
  id: root

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
}
