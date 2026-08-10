pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool matugenAvailable: false
  property bool nmcliAvailable: false
  property bool ddcutilAvailable: false
  property bool cavaAvailable: false
  property bool mpvpaperAvailable: false
  property bool mpvAvailable: false
  property var checked: ({})

  readonly property var programsToCheck: ({
      "matugenAvailable": ["which", "matugen"],
      "nmcliAvailable": ["which", "nmcli"],
      "ddcutilAvailable": ["which", "ddcutil"],
      "cavaAvailable": ["which", "cava"],
      "mpvpaperAvailable": ["which", "mpvpaper"],
      "mpvAvailable": ["which", "mpv"]
    })

  property var checkQueue: []
  property bool isChecking: false

  function ensure(propertyName) {
    if (!programsToCheck[propertyName])
      return false;
    if (checked[propertyName])
      return root[propertyName];
    if (checker.currentProperty !== propertyName && !checkQueue.includes(propertyName)) {
      checkQueue.push(propertyName);
      processQueue();
    }
    return false;
  }

  function isChecked(propertyName) {
    return checked[propertyName] === true;
  }

  Process {
    id: checker
    running: false

    property string currentProperty: ""

    onExited: function (exitCode) {
      if (currentProperty !== "") {
        root[currentProperty] = (exitCode === 0);
        root.checked = Object.assign({}, root.checked, { [currentProperty]: true });
      }

      root.isChecking = false;
      root.processQueue();
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  function processQueue() {
    if (isChecking || checkQueue.length === 0) {
      return;
    }

    isChecking = true;
    const propertyName = checkQueue.shift();
    const command = programsToCheck[propertyName];

    checker.currentProperty = propertyName;
    checker.command = command;
    checker.running = true;
  }
}
