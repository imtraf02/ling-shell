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
  property var pendingFrameSources: ({})
  property var extractedFrameSources: ({})
  // A frame is only considered usable after mpv has finished writing it. This
  // keeps the static wallpaper as the safe fallback while the first frame is
  // prepared.
  property var generatedFrames: ({})

  signal liveWallpaperChanged(string screenName, string path)
  signal liveWallpaperListChanged(string screenName, int count)
  signal frameChanged(string screenName, string path)

  readonly property bool available: ProgramCheckerService.mpvpaperAvailable && ProgramCheckerService.mpvAvailable

  function init() {
    initialized = true;
    ProgramCheckerService.ensure("mpvpaperAvailable");
    ProgramCheckerService.ensure("mpvAvailable");
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

  function isRunningForScreen(screenName) {
    return root.available && hasLiveWallpaper(screenName);
  }

  function frameDirectory(screenName) {
    return Directories.shellCacheWallpaperDir + "/live-" + screenName.replace(/[^a-zA-Z0-9_.-]/g, "_");
  }

  function framePath(screenName) {
    return frameDirectory(screenName) + "/00000001.jpg";
  }

  function hasFrame(screenName) {
    return generatedFrames[screenName] === true;
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
    root.generatedFrames = Object.assign({}, root.generatedFrames, { [screenName]: false });
    root.extractedFrameSources = Object.assign({}, root.extractedFrameSources, { [screenName]: "" });
    Settings.wallpaper.liveWallpapers = next;
    root.liveWallpaperChanged(screenName, path);
  }

  function clearLiveWallpaper(screenName) {
    const entries = Settings.wallpaper.liveWallpapers || [];
    Settings.wallpaper.liveWallpapers = entries.filter(entry => entry.name !== screenName);
    root.generatedFrames = Object.assign({}, root.generatedFrames, { [screenName]: false });
    root.extractedFrameSources = Object.assign({}, root.extractedFrameSources, { [screenName]: "" });
    root.pendingFrameSources = Object.assign({}, root.pendingFrameSources, { [screenName]: "" });
    root.liveWallpaperChanged(screenName, "");
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

  function extractFrame(screenName, path) {
    if (!ProgramCheckerService.ensure("mpvAvailable") || !path)
      return;
    if (root.extractedFrameSources[screenName] === path && root.hasFrame(screenName))
      return;
    if (root.pendingFrameSources[screenName] === path)
      return;
    root.pendingFrameSources = Object.assign({}, root.pendingFrameSources, { [screenName]: path });
    const directory = frameDirectory(screenName);
    const mkdir = Qt.createQmlObject(`
      import Quickshell.Io
      Process {}
    `, root, "LiveWallpaperFrameDirectory_" + screenName);
    mkdir.command = ["mkdir", "-p", directory];
    mkdir.exited.connect(exitCode => {
      mkdir.destroy();
      if (root.pendingFrameSources[screenName] !== path || root.getLiveWallpaper(screenName) !== path)
        return;
      if (exitCode !== 0) {
        root.pendingFrameSources = Object.assign({}, root.pendingFrameSources, { [screenName]: "" });
        return;
      }
      const extractor = Qt.createQmlObject(`
        import Quickshell.Io
        Process {
          stdout: StdioCollector {}
          stderr: StdioCollector {}
        }
      `, root, "LiveWallpaperFrame_" + screenName);
      extractor.command = ["mpv", "--no-config", "--really-quiet", "--frames=1", "--vo=image", "--vo-image-format=jpg", "--vo-image-outdir=" + directory, "--ao=null", path];
      extractor.exited.connect(result => {
        const isCurrent = root.pendingFrameSources[screenName] === path && root.getLiveWallpaper(screenName) === path;
        if (isCurrent && result === 0) {
          root.generatedFrames = Object.assign({}, root.generatedFrames, { [screenName]: true });
          root.extractedFrameSources = Object.assign({}, root.extractedFrameSources, { [screenName]: path });
          root.frameChanged(screenName, root.framePath(screenName));
        }
        if (isCurrent)
          root.pendingFrameSources = Object.assign({}, root.pendingFrameSources, { [screenName]: "" });
        extractor.destroy();
      });
      extractor.running = true;
    });
    mkdir.running = true;
  }

  Connections {
    target: Settings.wallpaper
    function onLiveWallpapersChanged() {
      const entries = Settings.wallpaper.liveWallpapers || [];
      for (let i = 0; i < entries.length; i)
        root.extractFrame(entries[i].name, entries[i].path);
    }
    function onDirectoryChanged() { if (root.catalogUsers > 0) root.refresh(); }
    function onEnableMultiMonitorDirectoriesChanged() { if (root.catalogUsers > 0) root.refresh(); }
    function onRecursiveSearchChanged() { if (root.catalogUsers > 0) root.refresh(); }
  }

  Connections {
    target: WallpaperService
    function onWallpaperDirectoryChanged() { if (root.catalogUsers > 0) root.refresh(); }
  }

  Connections {
    target: ProgramCheckerService
    function onMpvAvailableChanged() {
      if (!ProgramCheckerService.mpvAvailable)
        return;
      const entries = Settings.wallpaper.liveWallpapers || [];
      for (let i = 0; i < entries.length; i++)
        root.extractFrame(entries[i].name, entries[i].path);
    }
  }

  Instantiator {
    model: Settings.wallpaper.liveWallpapers || []
    delegate: Item {
      required property var modelData
      readonly property string output: modelData.name || ""
      readonly property string source: modelData.path || ""
      Component.onCompleted: root.extractFrame(output, source)
      Process {
        command: ["mpvpaper", "--auto-pause", "--mpv-options", "no-audio loop-file=inf hwdec=auto-safe cache=no demuxer-max-bytes=16MiB demuxer-max-back-bytes=4MiB vd-lavc-threads=2", parent.output, parent.source]
        running: root.initialized && root.available && parent.output !== "" && parent.source !== ""
      }
    }
  }
}
