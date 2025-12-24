pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property int sleepDuration: 3000

  property real cpuUsage: 0
  property real cpuTemp: 0
  property real memGb: 0
  property real memPercent: 0
  property var diskPercents: ({})
  property real rxSpeed: 0
  property real txSpeed: 0

  property var prevCpuStats: null

  property real prevRxBytes: 0
  property real prevTxBytes: 0
  property real prevTime: 0

  readonly property var supportedTempCpuSensorNames: ["coretemp", "k10temp", "zenpower"]
  property string cpuTempSensorName: ""
  property string cpuTempHwmonPath: ""
  property var intelTempValues: []
  property int intelTempFilesChecked: 0
  property int intelTempMaxFiles: 20

  Component.onCompleted: {
    cpuTempNameReader.checkNext();
  }

  Timer {
    id: updateTimer
    interval: root.sleepDuration
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: {
      memInfoFile.reload();
      cpuStatFile.reload();
      netDevFile.reload();
      dfProcess.running = true;
      root.updateCpuTemperature();
    }
  }

  FileView {
    id: memInfoFile
    path: "/proc/meminfo"
    onLoaded: root.parseMemoryInfo(text())
  }

  FileView {
    id: cpuStatFile
    path: "/proc/stat"
    onLoaded: root.calculateCpuUsage(text())
  }

  FileView {
    id: netDevFile
    path: "/proc/net/dev"
    onLoaded: root.calculateNetworkSpeed(text())
  }

  Process {
    id: dfProcess
    command: ["df", "--output=target,pcent"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split('\n');
        const newPercents = {};
        for (var i = 1; i < lines.length; i++) {
          const parts = lines[i].trim().split(/\s+/);
          if (parts.length >= 2) {
            const target = parts[0];
            const percent = parseInt(parts[1].replace(/[^0-9]/g, '')) || 0;
            newPercents[target] = percent;
          }
        }
        root.diskPercents = newPercents;
      }
    }
  }

  FileView {
    id: cpuTempNameReader
    property int currentIndex: 0
    printErrors: false

    function checkNext() {
      if (currentIndex >= 16)
        return;
      cpuTempNameReader.path = `/sys/class/hwmon/hwmon${currentIndex}/name`;
      cpuTempNameReader.reload();
    }

    onLoaded: {
      const name = text().trim();
      if (root.supportedTempCpuSensorNames.includes(name)) {
        root.cpuTempSensorName = name;
        root.cpuTempHwmonPath = `/sys/class/hwmon/hwmon${currentIndex}`;
      } else {
        currentIndex++;
        Qt.callLater(() => checkNext());
      }
    }

    onLoadFailed: {
      currentIndex++;
      Qt.callLater(() => checkNext());
    }
  }

  FileView {
    id: cpuTempReader
    printErrors: false

    onLoaded: {
      const data = text().trim();
      if (root.cpuTempSensorName === "coretemp") {
        const temp = parseInt(data) / 1000.0;
        root.intelTempValues.push(temp);
        Qt.callLater(() => root.checkNextIntelTemp());
      } else {
        root.cpuTemp = Math.round(parseInt(data) / 1000.0);
      }
    }

    onLoadFailed: {
      Qt.callLater(() => root.checkNextIntelTemp());
    }
  }

  function parseMemoryInfo(text) {
    if (!text)
      return;
    const lines = text.split('\n');
    let memTotal = 0;
    let memAvailable = 0;
    for (const line of lines) {
      if (line.startsWith('MemTotal:'))
        memTotal = parseInt(line.split(/\s+/)[1]) || 0;
      else if (line.startsWith('MemAvailable:'))
        memAvailable = parseInt(line.split(/\s+/)[1]) || 0;
    }
    if (memTotal > 0) {
      const usageKb = memTotal - memAvailable;
      root.memGb = (usageKb / 1048576).toFixed(1);
      root.memPercent = Math.round((usageKb / memTotal) * 100);
    }
  }

  function calculateCpuUsage(text) {
    if (!text)
      return;
    const lines = text.split('\n');
    const cpuLine = lines[0];
    if (!cpuLine.startsWith('cpu '))
      return;
    const parts = cpuLine.split(/\s+/);
    const stats = {
      "user": parseInt(parts[1]) || 0,
      "nice": parseInt(parts[2]) || 0,
      "system": parseInt(parts[3]) || 0,
      "idle": parseInt(parts[4]) || 0,
      "iowait": parseInt(parts[5]) || 0,
      "irq": parseInt(parts[6]) || 0,
      "softirq": parseInt(parts[7]) || 0,
      "steal": parseInt(parts[8]) || 0,
      "guest": parseInt(parts[9]) || 0,
      "guestNice": parseInt(parts[10]) || 0
    };
    const totalIdle = stats.idle + stats.iowait;
    const total = Object.values(stats).reduce((sum, val) => sum + val, 0);

    if (root.prevCpuStats) {
      const prevTotalIdle = root.prevCpuStats.idle + root.prevCpuStats.iowait;
      const prevTotal = Object.values(root.prevCpuStats).reduce((sum, val) => sum + val, 0);
      const diffTotal = total - prevTotal;
      const diffIdle = totalIdle - prevTotalIdle;
      if (diffTotal > 0)
        root.cpuUsage = (((diffTotal - diffIdle) / diffTotal) * 100).toFixed(1);
    }
    root.prevCpuStats = stats;
  }

  function calculateNetworkSpeed(text) {
    if (!text)
      return;
    const currentTime = Date.now() / 1000;
    const lines = text.split('\n');
    let totalRx = 0;
    let totalTx = 0;

    for (var i = 2; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line)
        continue;
      const colonIndex = line.indexOf(':');
      if (colonIndex === -1)
        continue;
      const iface = line.substring(0, colonIndex).trim();
      if (iface === 'lo')
        continue;
      const statsLine = line.substring(colonIndex + 1).trim();
      const stats = statsLine.split(/\s+/);
      const rxBytes = parseInt(stats[0], 10) || 0;
      const txBytes = parseInt(stats[8], 10) || 0;
      totalRx += rxBytes;
      totalTx += txBytes;
    }

    if (root.prevTime > 0) {
      const timeDiff = currentTime - root.prevTime;
      if (timeDiff > 0) {
        let rxDiff = totalRx - root.prevRxBytes;
        let txDiff = totalTx - root.prevTxBytes;
        if (rxDiff < 0)
          rxDiff = 0;
        if (txDiff < 0)
          txDiff = 0;
        root.rxSpeed = Math.round(rxDiff / timeDiff);
        root.txSpeed = Math.round(txDiff / timeDiff);
      }
    }

    root.prevRxBytes = totalRx;
    root.prevTxBytes = totalTx;
    root.prevTime = currentTime;
  }

  function formatSpeed(bytesPerSecond) {
    if (bytesPerSecond < 1024 * 1024) {
      const kb = bytesPerSecond / 1024;
      if (kb < 10)
        return kb.toFixed(1) + "KB";
      else
        return Math.round(kb) + "KB";
    } else if (bytesPerSecond < 1024 * 1024 * 1024) {
      return (bytesPerSecond / (1024 * 1024)).toFixed(1) + "MB";
    } else {
      return (bytesPerSecond / (1024 * 1024 * 1024)).toFixed(1) + "GB";
    }
  }

  function formatCompactSpeed(bytesPerSecond) {
    if (!bytesPerSecond || bytesPerSecond <= 0)
      return "0";
    const units = ["", "K", "M", "G"];
    let value = bytesPerSecond;
    let unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value = value / 1024.0;
      unitIndex++;
    }
    if (unitIndex < units.length - 1 && value >= 100) {
      value = value / 1024.0;
      unitIndex++;
    }
    const display = Math.round(value).toString();
    return display + units[unitIndex];
  }

  function updateCpuTemperature() {
    if (root.cpuTempSensorName === "k10temp" || root.cpuTempSensorName === "zenpower") {
      cpuTempReader.path = `${root.cpuTempHwmonPath}/temp1_input`;
      cpuTempReader.reload();
    } else if (root.cpuTempSensorName === "coretemp") {
      root.intelTempValues = [];
      root.intelTempFilesChecked = 0;
      checkNextIntelTemp();
    }
  }

  function checkNextIntelTemp() {
    if (root.intelTempFilesChecked >= root.intelTempMaxFiles) {
      if (root.intelTempValues.length > 0) {
        let sum = 0;
        for (var i = 0; i < root.intelTempValues.length; i++)
          sum += root.intelTempValues[i];
        root.cpuTemp = Math.round(sum / root.intelTempValues.length);
      } else {
        root.cpuTemp = 0;
      }
      return;
    }
    root.intelTempFilesChecked++;
    cpuTempReader.path = `${root.cpuTempHwmonPath}/temp
${root.intelTempFilesChecked}_input`;
    cpuTempReader.reload();
  }
}
