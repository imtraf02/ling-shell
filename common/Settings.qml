pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
  id: root

  property bool ready: false

  readonly property alias appearance: adapter.appearance
  readonly property alias bar: adapter.bar
  readonly property alias delay: adapter.delay
  readonly property alias brightness: adapter.brightness
  readonly property alias wallpaper: adapter.wallpaper
  readonly property alias network: adapter.network
  readonly property alias audio: adapter.audio
  readonly property alias launcher: adapter.launcher
  readonly property alias general: adapter.general
  readonly property alias session: adapter.session
  readonly property alias lock: adapter.lock
  readonly property alias notifications: adapter.notifications
  readonly property alias systemMonitor: adapter.systemMonitor
  readonly property alias dashboard: adapter.dashboard

  signal settingsLoaded
  signal settingsSaved

  // Defaults used by the Settings UI. Keep these plain values so a section can
  // be restored without replacing a JsonObject owned by the adapter.
  readonly property var sectionDefaults: ({
      general: {
        avatarImage: Directories.defaultAvatarPath,
        maxShown: 7,
        specialPrefix: "@",
        actionPrefix: ">",
        hiddenApps: [],
        maxWallpapers: 5
      },
      appearance: {
        thickness: 6,
        cornerRadius: 8,
        mode: "light",
        light: "Ling Light",
        dark: "Ling Dark",
        dynamic: false,
        matugenType: "scheme-tonal-spot",
        sans: "Rubik",
        mono: "CaskaydiaCove NF",
        clock: "Rubik"
      },
      bar: {
        persistent: false,
        showOnHover: false,
        pillDelay: 200,
        monitors: [],
        workspace: {
          shown: 5, activeIndicator: true, occupiedBg: false, showWindows: true,
          showWindowsOnSpecialWorkspaces: true, activeTrail: false,
          perMonitorWorkspaces: true, label: "  ", occupiedLabel: "󰮯",
          activeLabel: "󰮯", capitalisation: "preserve"
        },
        tray: { blacklist: [], favorites: [], colorize: false }
      },
      display: {
        brightnessStep: 5.0,
        enforceMinimum: true,
        enableDdcSupport: false,
        enabled: true,
        overviewEnabled: true,
        directory: Directories.defaultWallpaperDir,
        enableMultiMonitorDirectories: false,
        recursiveSearch: false,
        setWallpaperOnAllMonitors: true,
        defaultWallpaper: "",
        fillMode: "crop",
        fillColor: "#000000",
        monitors: [],
        liveWallpapers: [],
        transitionDuration: 500,
        transitionEdgeSmoothness: 0.05
      },
      network: {
        wifiEnabled: true, bluetoothRssiPollingEnabled: false,
        bluetoothRssiPollIntervalMs: 10000, bluetoothHideUnnamedDevices: false,
        wifiDetailsViewMode: "grid", networkPanelView: "wifi"
      },
      audio: {
        volumeStep: 5.0, volumeOverdrive: false, cavaFrameRate: 30,
        visualizerType: "linear", mprisBlacklist: [], preferredPlayer: ""
      },
      notifications: {
        enabled: true, expire: true, defaultExpireTimeout: 5000,
        clearThreshold: 0.3, expandThreshold: 20, actionOnClick: false,
        groupPreviewNum: 3, historyLimit: 100, historyRetentionDays: 30
      },
      dashboard: {
        enabled: true, defaultTab: "home", showHome: true, showMedia: true,
        showPerformance: true, showWeather: true,
        weatherLocation: "Ho Chi Minh City", weatherRefreshInterval: 1800000,
        performance: {
          showCpu: true, showGpu: true, showMemory: true, showSwap: true,
          showStorage: true, showNetwork: true, showBattery: true
        }
      },
      system: {
        gif: "root:/assets/jingliu.gif", dragThreshold: 30, vimKeybinds: false,
        recolourLogo: false, enableFprint: true, maxFprintTries: 3,
        cpuWarningThreshold: 80, cpuCriticalThreshold: 90,
        tempWarningThreshold: 80, tempCriticalThreshold: 90,
        gpuWarningThreshold: 80, gpuCriticalThreshold: 90,
        memWarningThreshold: 80, memCriticalThreshold: 90,
        swapWarningThreshold: 80, swapCriticalThreshold: 90,
        diskWarningThreshold: 80, diskCriticalThreshold: 90,
        cpuPollingInterval: 3000, tempPollingInterval: 3000,
        gpuPollingInterval: 3000, enableDgpuMonitoring: false,
        memPollingInterval: 3000, diskPollingInterval: 30000,
        networkPollingInterval: 3000, loadAvgPollingInterval: 3000,
        useCustomColors: false, warningColor: "", criticalColor: "",
        externalMonitor: "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor"
      }
    })

  Component.onCompleted: {
    settingsFileView.adapter = adapter;
  }

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

  function resetSection(sectionId) {
    const d = sectionDefaults[sectionId];
    if (!d)
      return;

    if (sectionId === "general") {
      general.avatarImage = d.avatarImage;
      launcher.maxShown = d.maxShown;
      launcher.specialPrefix = d.specialPrefix;
      launcher.actionPrefix = d.actionPrefix;
      launcher.hiddenApps = d.hiddenApps.slice();
      launcher.maxWallpapers = d.maxWallpapers;
    } else if (sectionId === "appearance") {
      appearance.thickness = d.thickness;
      appearance.cornerRadius = d.cornerRadius;
      appearance.theme.mode = d.mode;
      appearance.theme.light = d.light;
      appearance.theme.dark = d.dark;
      appearance.theme.dynamic = d.dynamic;
      appearance.theme.matugenType = d.matugenType;
      appearance.font.sans = d.sans;
      appearance.font.mono = d.mono;
      appearance.font.clock = d.clock;
    } else if (sectionId === "bar") {
      bar.persistent = d.persistent;
      bar.showOnHover = d.showOnHover;
      delay.pill = d.pillDelay;
      bar.monitors = d.monitors.slice();
      Object.assign(bar.workspace, d.workspace);
      bar.tray.blacklist = d.tray.blacklist.slice();
      bar.tray.favorites = d.tray.favorites.slice();
      bar.tray.colorize = d.tray.colorize;
    } else if (sectionId === "display") {
      brightness.brightnessStep = d.brightnessStep;
      brightness.enforceMinimum = d.enforceMinimum;
      brightness.enableDdcSupport = d.enableDdcSupport;
      wallpaper.enabled = d.enabled;
      wallpaper.overviewEnabled = d.overviewEnabled;
      wallpaper.directory = d.directory;
      wallpaper.enableMultiMonitorDirectories = d.enableMultiMonitorDirectories;
      wallpaper.recursiveSearch = d.recursiveSearch;
      wallpaper.setWallpaperOnAllMonitors = d.setWallpaperOnAllMonitors;
      wallpaper.defaultWallpaper = d.defaultWallpaper;
      wallpaper.fillMode = d.fillMode;
      wallpaper.fillColor = d.fillColor;
      wallpaper.monitors = d.monitors.slice();
      wallpaper.liveWallpapers = d.liveWallpapers.slice();
      wallpaper.transitionDuration = d.transitionDuration;
      wallpaper.transitionEdgeSmoothness = d.transitionEdgeSmoothness;
    } else if (sectionId === "network" || sectionId === "audio" || sectionId === "notifications" || sectionId === "dashboard") {
      const target = sectionId === "network" ? network : (sectionId === "audio" ? audio : (sectionId === "notifications" ? notifications : dashboard));
      for (const key in d) {
        if (sectionId === "dashboard" && key === "performance")
          Object.assign(target.performance, d.performance);
        else
          target[key] = Array.isArray(d[key]) ? d[key].slice() : d[key];
      }
    } else if (sectionId === "system") {
      const sessionKeys = ["gif", "dragThreshold", "vimKeybinds"];
      const lockKeys = ["recolourLogo", "enableFprint", "maxFprintTries"];
      for (const key of sessionKeys)
        session[key] = d[key];
      for (const key of lockKeys)
        lock[key] = d[key];
      for (const key in d) {
        if (!sessionKeys.includes(key) && !lockKeys.includes(key))
          systemMonitor[key] = d[key];
      }
    }
    saveImmediate();
  }

  FileView {
    id: settingsFileView
    path: Directories.shellConfigSettingsPath
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: saveTimer.start()
    onPathChanged: {
      if (path !== undefined) {
        reload();
      }
    }
    onLoaded: function () {
      if (!root.ready) {
        root.ready = true;
        root.settingsLoaded();
      }
    }
    onLoadFailed: function (error) {
      if (error === FileViewError.FileNotFound) {
        writeAdapter();
      }
    }
  }

  JsonAdapter {
    id: adapter

    property General general: General {}
    property Appearance appearance: Appearance {}
    property Bar bar: Bar {}
    property Delay delay: Delay {}
    property Brightness brightness: Brightness {}
    property Wallpaper wallpaper: Wallpaper {}
    property Network network: Network {}
    property Audio audio: Audio {}
    property Launcher launcher: Launcher {}
    property Session session: Session {}
    property Lock lock: Lock {}
    property Notifications notifications: Notifications {}
    property SystemMonitor systemMonitor: SystemMonitor {}
    property Dashboard dashboard: Dashboard {}
  }

  component Bar: JsonObject {
    property bool persistent: false
    property bool showOnHover: false
    property list<string> monitors: []
    property Workspace workspace: Workspace {}
    property Tray tray: Tray {}
    property JsonObject widgets: JsonObject {
      property list<var> left: [
        {
          id: "OsIcon"
        },
        {
          id: "Workspace"
        },
        {
          id: "Media"
        }
      ]
      property list<var> center: [
        {
          id: "Clock"
        }
      ]
      property list<var> right: [
        {
          id: "Tray"
        },
        {
          id: "Volume"
        },
        {
          id: "Brightness"
        },
        {
          id: "Network"
        },
        {
          id: "Battery"
        }
      ]
    }
  }

  component Appearance: JsonObject {
    property int thickness: 6
    property int cornerRadius: 8
    property Theme theme: Theme {}
    property FontStuff font: FontStuff {}
  }

  component Theme: JsonObject {
    property string mode: "light"
    property string light: "Ling Light"
    property string dark: "Ling Dark"
    property bool dynamic: false
    property string matugenType: "scheme-tonal-spot"
  }

  component FontStuff: JsonObject {
    property string sans: "Rubik"
    property string mono: "CaskaydiaCove NF"
    property string clock: "Rubik"
  }

  component Delay: JsonObject {
    property int pill: 200
  }

  component Brightness: JsonObject {
    property real brightnessStep: 5.0
    property bool enforceMinimum: true
    property bool enableDdcSupport: false
  }

  component Wallpaper: JsonObject {
    property bool enabled: true
    property bool overviewEnabled: true
    property string directory: Directories.defaultWallpaperDir
    property bool enableMultiMonitorDirectories: false
    property bool recursiveSearch: false
    property bool setWallpaperOnAllMonitors: true
    property string defaultWallpaper: ""
    property string fillMode: "crop"
    property color fillColor: "#000000"
    property list<var> monitors: []
    property list<var> liveWallpapers: []
    property int transitionDuration: 500
    property real transitionEdgeSmoothness: 0.05
  }

  component Network: JsonObject {
    property bool wifiEnabled: true
    property bool bluetoothRssiPollingEnabled: false
    property int bluetoothRssiPollIntervalMs: 10000
    property bool bluetoothHideUnnamedDevices: false
    property string wifiDetailsViewMode: "grid"
    property string networkPanelView: "wifi"
  }

  component Audio: JsonObject {
    property real volumeStep: 5.0
    property bool volumeOverdrive: false
    property int cavaFrameRate: 30
    property string visualizerType: "linear"
    property list<string> mprisBlacklist: []
    property string preferredPlayer: ""
  }

  component Workspace: JsonObject {
    property int shown: 5
    property bool activeIndicator: true
    property bool occupiedBg: false
    property bool showWindows: true
    property bool showWindowsOnSpecialWorkspaces: showWindows
    property bool activeTrail: false
    property bool perMonitorWorkspaces: true
    property string label: "  "
    property string occupiedLabel: "󰮯"
    property string activeLabel: "󰮯"
    property string capitalisation: "preserve"
  }

  component Tray: JsonObject {
    property list<string> blacklist: []
    property list<string> favorites: []
    property bool colorize: false
  }

  component Launcher: JsonObject {
    property int maxShown: 7
    property string specialPrefix: "@"
    property string actionPrefix: ">"
    property list<string> hiddenApps: []
    property int maxWallpapers: 5
  }

  component General: JsonObject {
    property string avatarImage: Directories.defaultAvatarPath
  }

  component Session: JsonObject {
    property string gif: "root:/assets/jingliu.gif"
    property int dragThreshold: 30
    property bool vimKeybinds: false
  }

  component Lock: JsonObject {
    property bool recolourLogo: false
    property bool enableFprint: true
    property int maxFprintTries: 3
  }

  component Notifications: JsonObject {
    property bool enabled: true
    property bool expire: true
    property int defaultExpireTimeout: 5000
    property real clearThreshold: 0.3
    property int expandThreshold: 20
    property bool actionOnClick: false
    property int groupPreviewNum: 3
    property int historyLimit: 100
    property int historyRetentionDays: 30
  }

  component Dashboard: JsonObject {
    property bool enabled: true
    property string defaultTab: "home"
    property bool showHome: true
    property bool showMedia: true
    property bool showPerformance: true
    property bool showWeather: true
    property string weatherLocation: "Ho Chi Minh City"
    property int weatherRefreshInterval: 1800000
    property DashboardPerformance performance: DashboardPerformance {}
  }

  component DashboardPerformance: JsonObject {
    property bool showCpu: true
    property bool showGpu: true
    property bool showMemory: true
    property bool showSwap: true
    property bool showStorage: true
    property bool showNetwork: true
    property bool showBattery: true
  }

  component SystemMonitor: JsonObject {
    property int cpuWarningThreshold: 80
    property int cpuCriticalThreshold: 90
    property int tempWarningThreshold: 80
    property int tempCriticalThreshold: 90
    property int gpuWarningThreshold: 80
    property int gpuCriticalThreshold: 90
    property int memWarningThreshold: 80
    property int memCriticalThreshold: 90
    property int swapWarningThreshold: 80
    property int swapCriticalThreshold: 90
    property int diskWarningThreshold: 80
    property int diskCriticalThreshold: 90
    property int cpuPollingInterval: 3000
    property int tempPollingInterval: 3000
    property int gpuPollingInterval: 3000
    property bool enableDgpuMonitoring: false
    property int memPollingInterval: 3000
    property int diskPollingInterval: 30000
    property int networkPollingInterval: 3000
    property int loadAvgPollingInterval: 3000
    property bool useCustomColors: false
    property string warningColor: ""
    property string criticalColor: ""
    property string externalMonitor: "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor"
  }
}
