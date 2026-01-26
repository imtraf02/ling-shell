pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // Public properties
  property string osPretty: ""
  property string osLogo: ""
  property bool isNixOS: false
  property bool isReady: false

  property string uptime: "--"
  readonly property string user: Quickshell.env("USER") || "user"
  readonly property string wm: Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP")
  readonly property string shell: Quickshell.env("SHELL").split("/").pop()

  function init() {
  }

  // Internal helpers
  function buildCandidates(name) {
    const n = (name || "").trim();
    if (!n) {
      return [];
    }

    const sizes = ["512x512", "256x256", "128x128", "64x64", "48x48", "32x32", "24x24", "22x22", "16x16"];
    const exts = ["svg", "png"];
    const candidates = [];

    // pixmaps
    for (const ext of exts) {
      candidates.push(`/usr/share/pixmaps/${n}.${ext}`);
    }

    // hicolor scalable and raster sizes
    candidates.push(`/usr/share/icons/hicolor/scalable/apps/${n}.svg`);
    for (const s of sizes) {
      for (const ext of exts) {
        candidates.push(`/usr/share/icons/hicolor/${s}/apps/${n}.${ext}`);
      }
    }

    // NixOS hicolor paths
    candidates.push(`/run/current-system/sw/share/icons/hicolor/scalable/apps/${n}.svg`);
    for (const s of sizes) {
      for (const ext of exts) {
        candidates.push(`/run/current-system/sw/share/icons/hicolor/${s}/apps/${n}.${ext}`);
      }
    }

    // Generic icon themes under /usr/share/icons (common cases)
    for (const ext of exts) {
      candidates.push(`/usr/share/icons/${n}.${ext}`);
      candidates.push(`/usr/share/icons/${n}/${n}.${ext}`);
      candidates.push(`/usr/share/icons/${n}/apps/${n}.${ext}`);
    }

    return candidates;
  }

  function resolveLogo(name) {
    const all = buildCandidates(name);
    if (all.length === 0) {
      return;
    }

    const script = all.map(p => `if [ -f "${p}" ]; then echo "${p}"; exit 0; fi`).join("; ") + "; exit 1";
    probe.command = ["sh", "-c", script];
    probe.running = true;
  }

  // Read /etc/os-release and trigger resolution
  FileView {
    id: osInfo
    path: "/etc/os-release"
    onLoaded: {
      try {
        const lines = text().split("\n");
        const val = k => {
          const l = lines.find(x => x.startsWith(k + "="));
          return l ? l.split("=")[1].replace(/"/g, "") : "";
        };
        root.osPretty = val("PRETTY_NAME") || val("NAME");

        const osId = (val("ID") || "").toLowerCase();
        root.isNixOS = osId === "nixos" || (root.osPretty || "").toLowerCase().includes("nixos");
        const logoName = val("LOGO");
        if (logoName) {
          resolveLogo(logoName);
        }
        root.isReady = true;
      } catch (e) {}
    }
  }

  Process {
    id: probe
    onExited: (code, exitCode) => {
      const p = String(stdout.text || "").trim();
      if (code === 0 && p) {
        root.osLogo = `file://${p}`;
      } else {
        root.osLogo = "";
      }
    }
    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: uptimeProcess.running = true
  }

  Process {
    id: uptimeProcess
    command: ["cat", "/proc/uptime"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        var uptimeSeconds = parseFloat(this.text.trim().split(' ')[0]);
        root.uptime = TimeService.formatVagueHumanReadableDuration(uptimeSeconds);
        uptimeProcess.running = false;
      }
    }
  }
}
