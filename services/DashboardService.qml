pragma Singleton

import QtQuick
import Quickshell
import qs.common

Singleton {
  id: root

  property string currentTab: "home"

  function tabs() {
    const result = [];
    if (Settings.dashboard.showHome)
      result.push({ key: "home", label: "Home", icon: "home" });
    if (Settings.dashboard.showMedia)
      result.push({ key: "media", label: "Media", icon: "music_note" });
    if (Settings.dashboard.showPerformance)
      result.push({ key: "performance", label: "Performance", icon: "monitoring" });
    if (Settings.dashboard.showWeather)
      result.push({ key: "weather", label: "Weather", icon: "partly_cloudy_day" });
    if (result.length === 0)
      result.push({ key: "home", label: "Home", icon: "home" });
    return result;
  }

  function isAvailable(key) {
    return tabs().some(tab => tab.key === key);
  }

  function select(key) {
    if (isAvailable(key)) {
      currentTab = key;
      return true;
    }
    const available = tabs();
    currentTab = available.length > 0 ? available[0].key : "home";
    return false;
  }

  function selectRelative(offset) {
    const available = tabs();
    if (available.length < 2)
      return;
    let index = available.findIndex(tab => tab.key === currentTab);
    if (index < 0)
      index = 0;
    index = (index + offset + available.length) % available.length;
    currentTab = available[index].key;
  }

  function resetToDefault() {
    select(Settings.dashboard.defaultTab);
  }

  Component.onCompleted: resetToDefault()
}
