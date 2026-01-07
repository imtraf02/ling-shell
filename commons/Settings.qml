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
  readonly property alias launcher: adapter.launcher
  readonly property alias lock: adapter.lock
  readonly property alias delay: adapter.delay

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
    path: Directories.shellConfigSettingsPath
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

      property JsonObject general: JsonObject {
        property string avatarImage: Directories.defaultAvatarPath
      }

      property JsonObject appearance: JsonObject {
        property int thickness: 4
        property int cornerRadius: 8
        property JsonObject theme: JsonObject {
          property string mode: "light"
          property string light: "Ling Light"
          property string dark: "Ling Dark"
          property bool dynamic: false
          property string matugenType: "scheme-tonal-spot"
        }
        property JsonObject font: JsonObject {
          property string sans: "Inter"
          property string mono: "JetBrainsMono NF"
          property string clock: "Inter"
          property real scale: 1.0
          property int weight: Font.Normal
        }
      }

      property JsonObject bar: JsonObject {
        property bool persistent: false
        property bool showOnHover: false
      }

      property JsonObject wallpaper: JsonObject {
        property bool enabled: true
        property bool overviewEnabled: true
        property string directory: Directories.defaultWallpaperDir
        property bool enableMultiMonitorDirectories: false
        property bool recursiveSearch: false
        property bool setWallpaperOnAllMonitors: true
        property string defaultWallpaper: Directories.assetsPath + "/wallpapers/violet.jpg"
        property string fillMode: "crop"
        property color fillColor: "#000000"
        property list<var> monitors: []
        property int transitionDuration: 500
        property real transitionEdgeSmoothness: 0.05
      }

      property JsonObject audio: JsonObject {
        property real volumeStep: 5.0
        property bool volumeOverdrive: false
        property int cavaFrameRate: 60
        property string visualizerType: "linear"
        property list<string> mprisBlacklist: []
        property string preferredPlayer: ""
      }

      property JsonObject tray: JsonObject {
        property list<string> blacklist: []
        property list<string> favorites: []
        property bool colorize: false
      }

      property JsonObject brightness: JsonObject {
        property real brightnessStep: 5.0
        property bool enforceMinimum: true
        property bool enableDdcSupport: false
      }

      property JsonObject network: JsonObject {
        property bool wifiEnabled: true
      }

      property JsonObject session: JsonObject {
        property string gif: "root:/assets/jingliu.gif"
        property bool enabled: true
        property int dragThreshold: 30
        property bool vimKeybinds: false
        property JsonObject commands: JsonObject {
          property list<string> logout: ["loginctl", "terminate-user", ""]
          property list<string> shutdown: ["systemctl", "poweroff"]
          property list<string> hibernate: ["systemctl", "hibernate"]
          property list<string> reboot: ["systemctl", "reboot"]
        }
      }

      property JsonObject notifications: JsonObject {
        property bool enabled: true
        property string background: "root:/assets/kyoukai-no-kanata.png"
        property bool expire: true
        property int defaultExpireTimeout: 5000
        property real clearThreshold: 0.3
        property int expandThreshold: 20
        property bool actionOnClick: false
        property int groupPreviewNum: 3
      }

      property JsonObject launcher: JsonObject {
        property int maxShown: 7
        property string specialPrefix: "@"
        property string actionPrefix: ">"
        property list<string> hiddenApps: []
        property int maxWallpapers: 5
      }

      property JsonObject lock: JsonObject {
        property bool recolourLogo: false
        property bool enableFprint: true
        property int maxFprintTries: 3
      }

      property JsonObject delay: JsonObject {
        property int pill: 1000
      }
    }
  }
}
