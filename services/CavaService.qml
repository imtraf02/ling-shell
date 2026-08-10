pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.services

Singleton {
  id: root

  property var registeredComponents: ({})

  property bool shouldRun: Object.keys(registeredComponents).length > 0
  readonly property bool available: ProgramCheckerService.cavaAvailable

  onShouldRunChanged: {
    if (shouldRun)
      ProgramCheckerService.ensure("cavaAvailable");
  }

  function registerComponent(componentId) {
    root.registeredComponents[componentId] = true;
    root.registeredComponents = Object.assign({}, root.registeredComponents);
  }

  function unregisterComponent(componentId) {
    delete root.registeredComponents[componentId];
    root.registeredComponents = Object.assign({}, root.registeredComponents);
  }

  property int barsCount: 24
  property var values: Array(barsCount).fill(0)

  property var config: ({
      "general": {
        "bars": barsCount,
        "framerate": Settings.audio.cavaFrameRate,
        "autosens": 1,
        "sensitivity": 100,
        "lower_cutoff_freq": 50,
        "higher_cutoff_freq": 12000
      },
      "smoothing": {
        "monstercat": 0,
        "noise_reduction": 77
      },
      "output": {
        "method": "raw",
        "data_format": "ascii",
        "ascii_max_range": 100,
        "bit_format": "8bit",
        "channels": "mono",
        "mono_option": "average"
      }
    })

  Process {
    id: process
    stdinEnabled: true
    running: root.shouldRun && root.available
    command: ["cava", "-p", "/dev/stdin"]

    onExited: {
      stdinEnabled = true;
      values = Array(root.barsCount).fill(0);
    }

    onStarted: {
      for (const k in root.config) {
        if (typeof root.config[k] !== "object") {
          write(k + "=" + root.config[k] + "\n");
          continue;
        }
        write("[" + k + "]\n");
        const obj = root.config[k];
        for (const k2 in obj)
          write(k2 + "=" + obj[k2] + "\n");
      }
      stdinEnabled = false;
      values = Array(root.barsCount).fill(0);
    }

    stdout: SplitParser {
      onRead: data => {
        const fields = String(data).trim().split(";").filter(value => value !== "");
        const nextValues = [];
        for (let i = 0; i < root.barsCount; i++) {
          const parsed = i < fields.length ? parseInt(fields[i], 10) : 0;
          nextValues.push(isFinite(parsed) ? Math.max(0, Math.min(1, parsed / 100)) : 0);
        }
        root.values = nextValues;
      }
    }

    stderr: StdioCollector {}
  }
}
