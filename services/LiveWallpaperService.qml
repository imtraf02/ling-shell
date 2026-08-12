pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.services

Singleton {
  id: root

  property bool initialized: false
  property int catalogUsers: 0
  property var liveWallpaperLists: ({})
  property var scanProcesses: ({})
  property var capturedFrameSources: ({})
  // The background surface captures a rendered Qt Multimedia frame. Until the
  // capture is complete, overview and dynamic colors keep using the static
  // wallpaper as their safe fallback.
  property var generatedFrames: ({})

  signal liveWallpaperChanged(string screenName, string path)
  signal liveWallpaperListChanged(string screenName, int count)
  signal frameChanged(string screenName, string path)

  readonly property bool available: true

  function init() {
    initialized = true;
  }

  function acquireCatalog() {
    catalogUsers++;
    if (catalogUsers === 1)
      refresh();
  }

  function releaseCatalog() {
    catalogUsers = Math.max(0, catalogUsers - 1);
    if (catalogUsers !== 0)
      return;
    for (const screenName in scanProcesses) {
      const process = scanProcesses[screenName];
      if (process) {
        process.cancelled = true;
        process.running = false;
      }
    }
    scanProcesses = ({});
    liveWallpaperLists = ({});
  }

  function getLiveWallpaper(screenName) {
    const entries = Settings.wallpaper.liveWallpapers || [];
    for (let i = 0; i < entries.length; i++) {
      if (entries[i].name === screenName)
        return entries[i].path || "";
    }
    return "";
  }

  function hasLiveWallpaper(screenName) {
    return getLiveWallpaper(screenName) !== "";
  }

  function framePath(screenName) {
    return Directories.shellCacheWallpaperDir + "/live-" + screenName.replace(/[^a-zA-Z0-9_.-]/g, "_") + ".jpg";
  }

  function hasFrame(screenName) {
    return generatedFrames[screenName] === true;
  }

  function needsFrame(screenName, path) {
    return path !== "" && getLiveWallpaper(screenName) === path && capturedFrameSources[screenName] !== path;
  }

  function markFrameReady(screenName, path) {
    if (!needsFrame(screenName, path))
      return;
    generatedFrames = Object.assign({}, generatedFrames, { [screenName]: true });
    capturedFrameSources = Object.assign({}, capturedFrameSources, { [screenName]: path });
    frameChanged(screenName, framePath(screenName));
  }

  function setLiveWallpaper(path, screenName) {
    if (!path)
      return;
    if (Settings.wallpaper.setWallpaperOnAllMonitors) {
      for (let i = 0; i < Quickshell.screens.length; i++)
        setLiveWallpaperForScreen(path, Quickshell.screens[i].name);
    } else {
      setLiveWallpaperForScreen(path, screenName);
    }
  }

  function setLiveWallpaperForScreen(path, screenName) {
    if (getLiveWallpaper(screenName) === path)
      return;
    const entries = Settings.wallpaper.liveWallpapers || [];
    let found = false;
    const next = entries.map(entry => {
      if (entry.name === screenName) {
        found = true;
        return { name: screenName, path: path };
      }
      return entry;
    });
    if (!found)
      next.push({ name: screenName, path: path });
    generatedFrames = Object.assign({}, generatedFrames, { [screenName]: false });
    capturedFrameSources = Object.assign({}, capturedFrameSources, { [screenName]: "" });
    Settings.wallpaper.liveWallpapers = next;
    liveWallpaperChanged(screenName, path);
  }

  function clearLiveWallpaper(screenName) {
    const entries = Settings.wallpaper.liveWallpapers || [];
    Settings.wallpaper.liveWallpapers = entries.filter(entry => entry.name !== screenName);
    generatedFrames = Object.assign({}, generatedFrames, { [screenName]: false });
    capturedFrameSources = Object.assign({}, capturedFrameSources, { [screenName]: "" });
    liveWallpaperChanged(screenName, "");
  }

  function getLiveWallpapersList(screenName) {
    return liveWallpaperLists[screenName] || [];
  }

  function refresh() {
    if (catalogUsers <= 0)
      return;
    for (let i = 0; i < Quickshell.screens.length; i++) {
      const screen = Quickshell.screens[i];
      scanScreen(screen.name, WallpaperService.getMonitorDirectory(screen.name));
    }
  }

  function scanScreen(screenName, directory) {
    if (catalogUsers <= 0 || !directory)
      return;
    if (scanProcesses[screenName]) {
      scanProcesses[screenName].cancelled = true;
      scanProcesses[screenName].running = false;
      delete scanProcesses[screenName];
    }
    const process = Qt.createQmlObject(`
      import Quickshell.Io
      Process {
        property bool cancelled: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
      }
    `, root, "LiveWallpaperScan_" + screenName);
    scanProcesses[screenName] = process;
    const depth = Settings.wallpaper.recursiveSearch ? [] : ["-maxdepth", "1"];
    process.command = ["find", directory].concat(depth, ["-type", "f", "(", "-iname", "*.mp4", "-o", "-iname", "*.webm", "-o", "-iname", "*.mkv", "-o", "-iname", "*.mov", "-o", "-iname", "*.avi", "-o", "-iname", "*.gif", ")"]);
    process.exited.connect(exitCode => {
      if (!process.cancelled && root.catalogUsers > 0) {
        const files = exitCode === 0 ? process.stdout.text.split("\n").map(path => path.trim()).filter(Boolean).sort() : [];
        root.liveWallpaperLists = Object.assign({}, root.liveWallpaperLists, { [screenName]: files });
        root.liveWallpaperListChanged(screenName, files.length);
      }
      if (root.scanProcesses[screenName] === process)
        delete root.scanProcesses[screenName];
      process.destroy();
    });
    process.running = true;
  }

  Connections {
    target: Settings.wallpaper
    function onDirectoryChanged() { if (root.catalogUsers > 0) root.refresh(); }
    function onEnableMultiMonitorDirectoriesChanged() { if (root.catalogUsers > 0) root.refresh(); }
    function onRecursiveSearchChanged() { if (root.catalogUsers > 0) root.refresh(); }
  }

  Connections {
    target: WallpaperService
    function onWallpaperDirectoryChanged() { if (root.catalogUsers > 0) root.refresh(); }
  }
}
