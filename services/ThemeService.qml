pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons
import qs.services

Singleton {
  id: root

  readonly property string themesDirectory: Quickshell.shellDir + "/assets/themes"
  readonly property string stateFilePath: Directories.shellConfigColoursPath

  property list<string> themeFiles: []
  property bool loading: false
  property alias palette: adapter

  readonly property list<string> validMatugenSchemes: ["scheme-content", "scheme-expressive", "scheme-fidelity", "scheme-fruit-salad", "scheme-monochrome", "scheme-neutral", "scheme-rainbow", "scheme-tonal-spot", "scheme-vibrant"]

  readonly property var matugenMap: ({
      primary: "mPrimary",
      on_primary: "mOnPrimary",
      primary_container: "mPrimaryContainer",
      on_primary_container: "mOnPrimaryContainer",
      secondary: "mSecondary",
      on_secondary: "mOnSecondary",
      tertiary: "mTertiary",
      on_tertiary: "mOnTertiary",
      background: "mBackground",
      on_background: "mOnBackground",
      surface: "mSurface",
      on_surface: "mOnSurface",
      surface_variant: "mSurfaceVariant",
      on_surface_variant: "mOnSurfaceVariant",
      surface_container: "mSurfaceContainer",
      surface_container_low: "mSurfaceContainerLow",
      surface_container_high: "mSurfaceContainerHigh",
      surface_container_highest: "mSurfaceContainerHighest",
      surface_tint: "mSurfaceTint",
      outline: "mOutline",
      shadow: "mShadow",
      error: "mError",
      on_error: "mOnError",
      error_container: "mErrorContainer",
      on_error_container: "mOnErrorContainer"
    })

  function init() {
    root.loading = true;
    findProcess.running = true;
  }

  function refresh() {
    root.loading = true;
    const theme = Settings.appearance.theme;
    if (theme.dynamic) {
      generateFromWallpaper(theme.mode, theme.matugenType);
    } else {
      const name = theme[theme.mode];
      if (name) {
        loadTheme(name);
      } else {
        root.loading = false;
      }
    }
  }

  function loadTheme(name) {
    if (!name) {
      root.loading = false;
      return;
    }
    const slug = name.trim().toLowerCase().replace(/\s+/g, "-");
    const path = themeFiles.find(f => f.endsWith(slug + ".json"));

    if (path) {
      themeReader.path = "";
      themeReader.path = path;
    } else {
      console.warn("Theme not found:", name);
      root.loading = false;
    }
  }

  function updateColors(data) {
    if (!data) {
      root.loading = false;
      return;
    }

    let changed = false;
    for (const key in data) {
      if (palette.hasOwnProperty(key) && palette[key] !== data[key]) {
        palette[key] = data[key];
        changed = true;
      }
    }
    if (changed)
      stateFileView.writeAdapter();

    root.loading = false;
  }

  function generateFromWallpaper(mode, type) {
    if (!ProgramCheckerService.matugenAvailable) {
      console.warn("Matugen not available");
      root.loading = false;
      return;
    }
    const wallpaper = WallpaperService.getWallpaper(Screen.name);
    if (!wallpaper) {
      console.warn("No wallpaper found");
      root.loading = false;
      return;
    }

    const matugenType = validMatugenSchemes.includes(type) ? type : "scheme-tonal-spot";
    const targetMode = mode === "light" ? "light" : "dark";
    generateProcess.command = ["matugen", "image", wallpaper, "-j", "hex", "-m", targetMode, "-t", matugenType];
    generateProcess.running = true;
  }

  function parseMatugen(json) {
    const result = {};
    const colors = json.colors || {};
    const mode = Settings.appearance.theme.mode === "light" ? "light" : "dark";

    for (const key in matugenMap) {
      const colorVal = colors[key]?.[mode];
      if (colorVal)
        result[matugenMap[key]] = colorVal;
    }
    return result;
  }

  function getDisplayName(path) {
    if (!path)
      return "";
    return path.split("/").pop().replace(/\.json$/i, "").split("-").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
  }

  Connections {
    target: Settings.appearance.theme

    function onModeChanged() {
      root.refresh();
    }

    function onDynamicChanged() {
      root.refresh();
    }

    function onMatugenTypeChanged() {
      if (Settings.appearance.theme.dynamic) {
        root.refresh();
      }
    }

    function onLightChanged() {
      if (Settings.appearance.theme.mode === "light" && !Settings.appearance.theme.dynamic) {
        root.loadTheme(Settings.appearance.theme.light);
      }
    }

    function onDarkChanged() {
      if (Settings.appearance.theme.mode === "dark" && !Settings.appearance.theme.dynamic) {
        root.loadTheme(Settings.appearance.theme.dark);
      }
    }
  }

  Connections {
    target: WallpaperService
    function onWallpaperChanged() {
      if (Settings.appearance.theme.dynamic)
        root.refresh();
    }
  }

  Process {
    id: findProcess
    command: ["find", root.themesDirectory, "-name", "*.json", "-type", "f"]
    onExited: exitCode => {
      if (exitCode === 0) {
        themeFiles = stdout.text.trim().split("\n").filter(Boolean);
      } else {
        console.error("Find Theme Error:", stderr.text);
      }
      root.refresh();
    }
    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  Process {
    id: generateProcess
    workingDirectory: Quickshell.shellDir
    running: false
    onExited: exitCode => {
      if (exitCode === 0) {
        try {
          root.updateColors(root.parseMatugen(JSON.parse(stdout.text.trim())));
        } catch (e) {
          console.error("Matugen Parse Error:", e);
          root.loading = false;
        }
      } else {
        console.error("Matugen Error:", stderr.text);
        root.loading = false;
      }
    }
    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  FileView {
    id: themeReader
    onLoaded: {
      try {
        root.updateColors(JSON.parse(text()));
      } catch (e) {
        console.error("Theme Load Error:", e);
        root.loading = false;
      }
    }
  }

  FileView {
    id: stateFileView
    path: root.stateFilePath
    watchChanges: true
    onFileChanged: reload()
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound)
        writeAdapter();
      else
        console.error("State File Error:", error);
    }

    JsonAdapter {
      id: adapter
      property color mPrimary: "#c4cd7b"
      property color mOnPrimary: "#2e3300"
      property color mPrimaryContainer: "#444b05"
      property color mOnPrimaryContainer: "#e0e994"
      property color mSecondary: "#c7c9a7"
      property color mOnSecondary: "#2f321a"
      property color mTertiary: "#a2d0c1"
      property color mOnTertiary: "#06372d"
      property color mBackground: "#13140d"
      property color mOnBackground: "#e5e3d6"
      property color mSurface: "#13140d"
      property color mOnSurface: "#e5e3d6"
      property color mSurfaceVariant: "#47483b"
      property color mOnSurfaceVariant: "#c8c7b7"
      property color mSurfaceTint: "#c4cd7b"
      property color mOutline: "#929282"
      property color mShadow: "#000000"
      property color mError: "#ffb4ab"
      property color mOnError: "#690005"
      property color mErrorContainer: "#93000a"
      property color mOnErrorContainer: "#ffdad6"
      property color mSurfaceContainer: "#202018"
      property color mSurfaceContainerLow: "#1c1c14"
      property color mSurfaceContainerHigh: "#2a2b22"
      property color mSurfaceContainerHighest: "#35352d"
    }
  }
}
