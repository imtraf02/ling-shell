pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons

Singleton {
  id: root

  property bool ready: false

  readonly property alias general: adapter.general
  readonly property alias appearance: adapter.appearance
  readonly property alias bar: adapter.bar
  readonly property alias wallpaper: adapter.wallpaper
  readonly property alias audio: adapter.audio
  readonly property alias tray: adapter.tray
  readonly property alias brightness: adapter.brightness
  readonly property alias network: adapter.network
  readonly property alias session: adapter.session
  readonly property alias notifications: adapter.notifications

  signal settingsSaved

  Timer {
    id: saveTimer
    running: false
    interval: 1000
    onTriggered: {
      root.saveImmediate();
    }
  }

  function saveImmediate() {
    settingsFileView.writeAdapter();
    root.ready = true;
    root.settingsSaved();
  }

  FileView {
    id: settingsFileView
    path: Directories.shellStateSettingsPath
    watchChanges: true
    onAdapterUpdated: saveTimer.restart()
    onLoaded: {
      root.ready = true;
    }
    onLoadFailed: error => {
      if (error == FileViewError.FileNotFound) {
        saveTimer.restart();
      }
    }

    JsonAdapter {
      id: adapter

      property GeneralSettings general: GeneralSettings {}
      property AppearanceSettings appearance: AppearanceSettings {}
      property BarSettings bar: BarSettings {}
      property WallpaperSettings wallpaper: WallpaperSettings {}
      property AudioSettings audio: AudioSettings {}
      property TraySettings tray: TraySettings {}
      property BrightnessSettings brightness: BrightnessSettings {}
      property NetworkSettings network: NetworkSettings {}
      property SessionSettings session: SessionSettings {}
      property NotificationsSettings notifications: NotificationsSettings {}
    }
  }
}
