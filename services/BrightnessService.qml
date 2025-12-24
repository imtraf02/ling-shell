pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons

Singleton {
  id: root

  property list<var> ddcMonitors: []
  readonly property list<Monitor> monitors: variants.instances
  property bool appleDisplayPresent: false
  reloadableId: "brightness"

  function getMonitorForScreen(screen: ShellScreen): var {
    return monitors.find(m => m.modelData === screen);
  }

  function getAvailableMethods(): list<string> {
    var methods = [];
    if (Settings.brightness.enableDdcSupport && monitors.some(m => m.isDdc))
      methods.push("ddcutil");
    if (monitors.some(m => !m.isDdc))
      methods.push("internal");
    if (appleDisplayPresent)
      methods.push("apple");
    return methods;
  }

  function increaseBrightness(): void {
    monitors.forEach(m => m.increaseBrightness());
  }

  function decreaseBrightness(): void {
    monitors.forEach(m => m.decreaseBrightness());
  }

  function getDetectedDisplays(): list<var> {
    return detectedDisplays;
  }

  signal monitorBrightnessChanged(var monitor, real newBrightness)

  Component.onCompleted: {
    if (Settings.brightness.enableDdcSupport) {
      ddcProc.running = true;
    }
  }

  onMonitorsChanged: {
    ddcMonitors = [];
    if (Settings.brightness.enableDdcSupport) {
      ddcProc.running = true;
    }
  }

  Connections {
    target: Settings.brightness
    function onEnableDdcSupportChanged() {
      if (Settings.brightness.enableDdcSupport) {
        ddcMonitors = [];
        ddcProc.running = true;
      } else {
        ddcMonitors = [];
      }
    }
  }

  Variants {
    id: variants
    model: Quickshell.screens
    Monitor {}
  }

  Process {
    running: true
    command: ["sh", "-c", "which asdbctl >/dev/null 2>&1 && asdbctl get || echo ''"]
    stdout: StdioCollector {
      onStreamFinished: root.appleDisplayPresent = text.trim().length > 0
    }
  }

  Process {
    id: ddcProc
    property list<var> ddcMonitors: []
    command: ["ddcutil", "detect", "--sleep-multiplier=0.5"]
    stdout: StdioCollector {
      onStreamFinished: {
        var displays = text.trim().split("\n\n");
        ddcProc.ddcMonitors = displays.map(d => {
          var ddcModelMatch = d.match(/(This monitor does not support DDC\/CI|Invalid display)/);
          var modelMatch = d.match(/Model:\s*(.*)/);
          var busMatch = d.match(/I2C bus:[ ]*\/dev\/i2c-([0-9]+)/);
          var ddcModel = ddcModelMatch ? ddcModelMatch.length > 0 : false;
          var model = modelMatch ? modelMatch[1] : "Unknown";
          var bus = busMatch ? busMatch[1] : "Unknown";
          return {
            "model": model,
            "busNum": bus,
            "isDdc": !ddcModel
          };
        });
        root.ddcMonitors = ddcProc.ddcMonitors.filter(m => m.isDdc);
      }
    }
  }

  component Monitor: QtObject {
    id: monitor

    required property ShellScreen modelData
    readonly property bool isDdc: Settings.brightness.enableDdcSupport && root.ddcMonitors.some(m => m.model === modelData.model)
    readonly property string busNum: root.ddcMonitors.find(m => m.model === modelData.model)?.busNum ?? ""
    readonly property bool isAppleDisplay: root.appleDisplayPresent && modelData.model.startsWith("StudioDisplay")
    readonly property string method: isAppleDisplay ? "apple" : (isDdc ? "ddcutil" : "internal")

    readonly property bool brightnessControlAvailable: {
      if (isAppleDisplay)
        return true;
      if (isDdc)
        return true;
      return brightnessPath !== "";
    }
    property real brightness
    property real lastBrightness: 0
    property real queuedBrightness: NaN

    property string backlightDevice: ""
    property string brightnessPath: ""
    property string maxBrightnessPath: ""
    property int maxBrightness: 100
    property bool ignoreNextChange: false

    signal brightnessUpdated(real newBrightness)

    readonly property Process refreshProc: Process {
      stdout: StdioCollector {
        onStreamFinished: {
          var dataText = text.trim();
          if (dataText === "")
            return;
          var lines = dataText.split("\n");
          if (lines.length >= 2) {
            var current = parseInt(lines[0].trim());
            var max = parseInt(lines[1].trim());
            if (!isNaN(current) && !isNaN(max) && max > 0) {
              var newBrightness = current / max;
              if (Math.abs(newBrightness - monitor.brightness) > 0.01) {
                monitor.brightness = newBrightness;
                monitor.brightnessUpdated(monitor.brightness);
                root.monitorBrightnessChanged(monitor, monitor.brightness);
              }
            }
          }
        }
      }
    }

    function refreshBrightnessFromSystem() {
      if (!monitor.isDdc && !monitor.isAppleDisplay) {
        refreshProc.command = ["sh", "-c", "cat " + monitor.brightnessPath + " && cat " + monitor.maxBrightnessPath];
      } else if (monitor.isDdc) {
        refreshProc.command = ["ddcutil", "-b", monitor.busNum, "getvcp", "10", "--brief"];
      } else if (monitor.isAppleDisplay) {
        refreshProc.command = ["asdbctl", "get"];
      }
      refreshProc.running = true;
    }

    readonly property FileView brightnessWatcher: FileView {
      id: brightnessWatcher
      path: (!monitor.isDdc && !monitor.isAppleDisplay && monitor.brightnessPath !== "") ? monitor.brightnessPath : ""
      watchChanges: path !== ""
      onFileChanged: Qt.callLater(() => monitor.refreshBrightnessFromSystem())
    }

    readonly property Process initProc: Process {
      stdout: StdioCollector {
        onStreamFinished: {
          var dataText = text.trim();
          if (dataText === "")
            return;
          if (monitor.isAppleDisplay) {
            var val = parseInt(dataText);
            if (!isNaN(val))
              monitor.brightness = val / 101;
          } else if (monitor.isDdc) {
            var parts = dataText.split(" ");
            if (parts.length >= 4) {
              var current = parseInt(parts[3]);
              var max = parseInt(parts[4]);
              if (!isNaN(current) && !isNaN(max) && max > 0)
                monitor.brightness = current / max;
            }
          } else {
            var lines = dataText.split("\n");
            if (lines.length >= 3) {
              monitor.backlightDevice = lines[0];
              monitor.brightnessPath = monitor.backlightDevice + "/brightness";
              monitor.maxBrightnessPath = monitor.backlightDevice + "/max_brightness";

              var current = parseInt(lines[1]);
              var max = parseInt(lines[2]);
              if (!isNaN(current) && !isNaN(max) && max > 0) {
                monitor.maxBrightness = max;
                monitor.brightness = current / max;
              }
            }
          }

          monitor.brightnessUpdated(monitor.brightness);
          root.monitorBrightnessChanged(monitor, monitor.brightness);
        }
      }
    }

    readonly property real stepSize: Settings.brightness.brightnessStep / 100.0
    readonly property real minBrightnessValue: (Settings.brightness.enforceMinimum ? 0.01 : 0.0)

    readonly property Timer timer: Timer {
      interval: 100
      onTriggered: {
        if (!isNaN(monitor.queuedBrightness)) {
          monitor.setBrightness(monitor.queuedBrightness);
          monitor.queuedBrightness = NaN;
        }
      }
    }

    function setBrightnessDebounced(value: real): void {
      monitor.queuedBrightness = value;
      timer.start();
    }

    function increaseBrightness(): void {
      const value = !isNaN(monitor.queuedBrightness) ? monitor.queuedBrightness : monitor.brightness;
      if (Settings.brightness.enforceMinimum && value <= minBrightnessValue) {
        setBrightnessDebounced(Math.max(stepSize, minBrightnessValue));
      } else {
        setBrightnessDebounced(value + stepSize);
      }
    }

    function decreaseBrightness(): void {
      const value = !isNaN(monitor.queuedBrightness) ? monitor.queuedBrightness : monitor.brightness;
      setBrightnessDebounced(value - stepSize);
    }

    function setBrightness(value: real): void {
      value = Math.max(minBrightnessValue, Math.min(1, value));
      var rounded = Math.round(value * 100);

      if (timer.running) {
        monitor.queuedBrightness = value;
        return;
      }

      monitor.brightness = value;
      monitor.brightnessUpdated(value);
      root.monitorBrightnessChanged(monitor, monitor.brightness);

      if (isAppleDisplay) {
        monitor.ignoreNextChange = true;
        Quickshell.execDetached(["asdbctl", "set", rounded]);
      } else if (isDdc) {
        monitor.ignoreNextChange = true;
        Quickshell.execDetached(["ddcutil", "-b", busNum, "setvcp", "10", rounded]);
      } else {
        monitor.ignoreNextChange = true;
        Quickshell.execDetached(["brightnessctl", "s", rounded + "%"]);
      }

      if (isDdc)
        timer.restart();
    }

    function initBrightness(): void {
      if (isAppleDisplay) {
        initProc.command = ["asdbctl", "get"];
      } else if (isDdc) {
        initProc.command = ["ddcutil", "-b", busNum, "getvcp", "10", "--brief"];
      } else {
        initProc.command = ["sh", "-c", "for dev in /sys/class/backlight/*; do " + "if [ -f \"$dev/brightness\" ] && [ -f \"$dev/max_brightness\" ]; then " + "echo \"$dev\"; cat \"$dev/brightness\"; cat \"$dev/max_brightness\"; break; fi; done"];
      }
      initProc.running = true;
    }

    onBusNumChanged: initBrightness()
    Component.onCompleted: initBrightness()
  }
}
