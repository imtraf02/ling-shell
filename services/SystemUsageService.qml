pragma Singleton
import Qt.labs.folderlistmodel

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.services

Singleton {
  id: root

  readonly property int minimumIntervalMs: 250
  readonly property int defaultIntervalMs: 3000
  property var activeConsumers: ({})
  readonly property bool active: Object.keys(activeConsumers).length > 0

  function normalizeInterval(value) {
    return Math.max(minimumIntervalMs, value || defaultIntervalMs);
  }

  property real cpuUsage: 0
  property real cpuTemp: 0
  property real gpuTemp: 0
  property bool gpuAvailable: false
  property string gpuType: ""
  property real memGb: 0
  property real memPercent: 0
  property real swapGb: 0
  property real swapPercent: 0
  property real swapTotalGb: 0
  property var diskPercents: ({})
  property var diskUsedGb: ({})
  property var diskSizeGb: ({})
  property real rxSpeed: 0
  property real txSpeed: 0
  property real zfsArcSizeKb: 0
  property real zfsArcCminKb: 0
  property real loadAvg1: 0
  property real loadAvg5: 0
  property real loadAvg15: 0
  property int nproc: 0

  readonly property real rxMaxSpeed: {
    const peaks = networkStatsAdapter.rxPeaks || [];
    return peaks.length > 0 ? Math.max(...peaks.map(p => p.speed)) : 0;
  }
  readonly property real txMaxSpeed: {
    const peaks = networkStatsAdapter.txPeaks || [];
    return peaks.length > 0 ? Math.max(...peaks.map(p => p.speed)) : 0;
  }

  readonly property real rxRatio: rxMaxSpeed > 0 ? Math.min(1, rxSpeed / rxMaxSpeed) : 0
  readonly property real txRatio: txMaxSpeed > 0 ? Math.min(1, txSpeed / txMaxSpeed) : 0

  readonly property color warningColor: Settings.systemMonitor.useCustomColors ? (Settings.systemMonitor.warningColor || ThemeService.palette.mTertiary) : ThemeService.palette.mTertiary
  readonly property color criticalColor: Settings.systemMonitor.useCustomColors ? (Settings.systemMonitor.criticalColor || ThemeService.palette.mError) : ThemeService.palette.mError

  readonly property int cpuWarningThreshold: Settings.systemMonitor.cpuWarningThreshold
  readonly property int cpuCriticalThreshold: Settings.systemMonitor.cpuCriticalThreshold
  readonly property int tempWarningThreshold: Settings.systemMonitor.tempWarningThreshold
  readonly property int tempCriticalThreshold: Settings.systemMonitor.tempCriticalThreshold
  readonly property int gpuWarningThreshold: Settings.systemMonitor.gpuWarningThreshold
  readonly property int gpuCriticalThreshold: Settings.systemMonitor.gpuCriticalThreshold
  readonly property int memWarningThreshold: Settings.systemMonitor.memWarningThreshold
  readonly property int memCriticalThreshold: Settings.systemMonitor.memCriticalThreshold
  readonly property int swapWarningThreshold: Settings.systemMonitor.swapWarningThreshold
  readonly property int swapCriticalThreshold: Settings.systemMonitor.swapCriticalThreshold
  readonly property int diskWarningThreshold: Settings.systemMonitor.diskWarningThreshold
  readonly property int diskCriticalThreshold: Settings.systemMonitor.diskCriticalThreshold

  readonly property bool cpuWarning: cpuUsage >= cpuWarningThreshold
  readonly property bool cpuCritical: cpuUsage >= cpuCriticalThreshold
  readonly property bool tempWarning: cpuTemp >= tempWarningThreshold
  readonly property bool tempCritical: cpuTemp >= tempCriticalThreshold
  readonly property bool gpuWarning: gpuAvailable && gpuTemp >= gpuWarningThreshold
  readonly property bool gpuCritical: gpuAvailable && gpuTemp >= gpuCriticalThreshold
  readonly property bool memWarning: memPercent >= memWarningThreshold
  readonly property bool memCritical: memPercent >= memCriticalThreshold
  readonly property bool swapWarning: swapPercent >= swapWarningThreshold
  readonly property bool swapCritical: swapPercent >= swapCriticalThreshold

  function isDiskWarning(diskPath) {
    return (diskPercents[diskPath] || 0) >= diskWarningThreshold;
  }

  function isDiskCritical(diskPath) {
    return (diskPercents[diskPath] || 0) >= diskCriticalThreshold;
  }

  readonly property color cpuColor: cpuCritical ? criticalColor : (cpuWarning ? warningColor : ThemeService.palette.mPrimary)

  readonly property color tempColor: tempCritical ? criticalColor : (tempWarning ? warningColor : ThemeService.palette.mPrimary)

  readonly property color gpuColor: gpuCritical ? criticalColor : (gpuWarning ? warningColor : ThemeService.palette.mPrimary)

  readonly property color memColor: memCritical ? criticalColor : (memWarning ? warningColor : ThemeService.palette.mPrimary)

  readonly property color swapColor: swapCritical ? criticalColor : (swapWarning ? warningColor : ThemeService.palette.mPrimary)

  function getDiskColor(diskPath) {
    return isDiskCritical(diskPath) ? criticalColor : (isDiskWarning(diskPath) ? warningColor : ThemeService.palette.mPrimary);
  }

  function getStatColor(value, warningThreshold, criticalThreshold) {
    if (value >= criticalThreshold)
      return criticalColor;
    if (value >= warningThreshold)
      return warningColor;
    return ThemeService.palette.mPrimary;
  }

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

  readonly property var supportedTempGpuSensorNames: ["amdgpu", "xe"]
  property string gpuTempHwmonPath: ""
  property var foundGpuSensors: []
  property int gpuVramCheckIndex: 0

  property string networkStatsFile: Settings.cacheDir + "network_stats.json"

  FileView {
    id: networkStatsView
    path: root.networkStatsFile
    printErrors: false

    JsonAdapter {
      id: networkStatsAdapter
      property var rxPeaks: []
      property var txPeaks: []
    }

    onLoadFailed: {
      networkStatsAdapter.rxPeaks = [];
      networkStatsAdapter.txPeaks = [];
    }

    onLoaded: {
      root.pruneExpiredPeaks();
    }
  }

  Timer {
    id: networkStatsSaveDebounce
    interval: 1000
    onTriggered: networkStatsView.writeAdapter()
  }

  function pruneExpiredPeaks() {
    const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
    const cutoff = Date.now() - sevenDaysMs;
    const rxBefore = (networkStatsAdapter.rxPeaks || []).length;
    const txBefore = (networkStatsAdapter.txPeaks || []).length;

    networkStatsAdapter.rxPeaks = (networkStatsAdapter.rxPeaks || []).filter(p => p.timestamp > cutoff);
    networkStatsAdapter.txPeaks = (networkStatsAdapter.txPeaks || []).filter(p => p.timestamp > cutoff);

    if (networkStatsAdapter.rxPeaks.length !== rxBefore || networkStatsAdapter.txPeaks.length !== txBefore) {
      networkStatsSaveDebounce.restart();
    }
  }

  function startSampling() {
    cpuTempNameReader.checkNext();
    gpuTempNameReader.checkNext();
    zfsArcStatsFile.reload();
    nprocProcess.running = true;
    loadAvgFile.reload();
  }

  function setConsumer(id, enabled) {
    const next = Object.assign({}, activeConsumers);
    if (enabled)
      next[id] = true;
    else
      delete next[id];
    const wasActive = active;
    activeConsumers = next;
    if (!wasActive && active)
      startSampling();
  }

  // Compatibility for external widgets using the previous API.
  function setActive(value) {
    setConsumer("legacy", value);
  }

  Connections {
    target: Settings.systemMonitor
    function onEnableDgpuMonitoringChanged() {
      if (root.active)
        restartGpuDetection();
    }
  }

  function restartGpuDetection() {
    root.gpuAvailable = false;
    root.gpuType = "";
    root.gpuTempHwmonPath = "";
    root.gpuTemp = 0;
    root.foundGpuSensors = [];
    root.gpuVramCheckIndex = 0;

    gpuTempNameReader.currentIndex = 0;
    gpuTempNameReader.checkNext();
  }

  Timer {
    id: cpuUsageTimer
    interval: root.normalizeInterval(Settings.systemMonitor.cpuPollingInterval)
    repeat: true
    running: root.active
    triggeredOnStart: true
    onIntervalChanged: {
      if (running) {
        restart();
      }
    }
    onTriggered: cpuStatFile.reload()
  }

  Timer {
    id: loadAvgTimer
    interval: root.normalizeInterval(Settings.systemMonitor.loadAvgPollingInterval)
    repeat: true
    running: root.active
    triggeredOnStart: true
    onIntervalChanged: {
      if (running) {
        restart();
      }
    }
    onTriggered: loadAvgFile.reload()
  }

  Timer {
    id: cpuTempTimer
    interval: root.normalizeInterval(Settings.systemMonitor.tempPollingInterval)
    repeat: true
    running: root.active
    triggeredOnStart: true
    onIntervalChanged: {
      if (running) {
        restart();
      }
    }
    onTriggered: updateCpuTemperature()
  }

  Timer {
    id: memoryTimer
    interval: root.normalizeInterval(Settings.systemMonitor.memPollingInterval)
    repeat: true
    running: root.active
    triggeredOnStart: true
    onIntervalChanged: {
      if (running) {
        restart();
      }
    }
    onTriggered: {
      memInfoFile.reload();
      zfsArcStatsFile.reload();
    }
  }

  Timer {
    id: diskTimer
    interval: root.normalizeInterval(Settings.systemMonitor.diskPollingInterval)
    repeat: true
    running: root.active
    triggeredOnStart: true
    onIntervalChanged: {
      if (running) {
        restart();
      }
    }
    onTriggered: dfProcess.running = true
  }

  Timer {
    id: networkTimer
    interval: root.normalizeInterval(Settings.systemMonitor.networkPollingInterval)
    repeat: true
    running: root.active
    triggeredOnStart: true
    onIntervalChanged: {
      if (running) {
        restart();
      }
    }
    onTriggered: netDevFile.reload()
  }

  Timer {
    id: gpuTempTimer
    interval: root.normalizeInterval(Settings.systemMonitor.gpuPollingInterval)
    repeat: true
    running: root.active && root.gpuAvailable
    triggeredOnStart: true
    onIntervalChanged: {
      if (running) {
        restart();
      }
    }
    onTriggered: updateGpuTemperature()
  }

  FileView {
    id: memInfoFile
    path: "/proc/meminfo"
    onLoaded: parseMemoryInfo(text())
  }

  FileView {
    id: cpuStatFile
    path: "/proc/stat"
    onLoaded: calculateCpuUsage(text())
  }

  FileView {
    id: netDevFile
    path: "/proc/net/dev"
    onLoaded: calculateNetworkSpeed(text())
  }

  FileView {
    id: loadAvgFile
    path: "/proc/loadavg"
    onLoaded: parseLoadAverage(text())
  }

  FileView {
    id: zfsArcStatsFile
    path: "/proc/spl/kstat/zfs/arcstats"
    printErrors: false
    onLoaded: parseZfsArcStats(text())
    onLoadFailed: {
      root.zfsArcSizeKb = 0;
      root.zfsArcCminKb = 0;
    }
  }

  Process {
    id: dfProcess
    command: ["df", "--output=target,pcent,used,size", "--block-size=1", "-x", "efivarfs"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        const newPercents = {};
        const newUsedGb = {};
        const newSizeGb = {};
        const bytesPerGb = 1024 * 1024 * 1024;

        for (let i = 1; i < lines.length; i++) {
          const parts = lines[i].trim().split(/\s+/);
          if (parts.length >= 4) {
            const target = parts[0];
            const percent = parseInt(parts[1].replace(/[^0-9]/g, "")) || 0;
            const usedBytes = parseFloat(parts[2]) || 0;
            const sizeBytes = parseFloat(parts[3]) || 0;
            newPercents[target] = percent;
            newUsedGb[target] = usedBytes / bytesPerGb;
            newSizeGb[target] = sizeBytes / bytesPerGb;
          }
        }

        root.diskPercents = newPercents;
        root.diskUsedGb = newUsedGb;
        root.diskSizeGb = newSizeGb;
      }
    }
  }

  Process {
    id: nprocProcess
    command: ["nproc"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.nproc = parseInt(text.trim());
      }
    }
  }

  FileView {
    id: cpuTempNameReader
    property int currentIndex: 0
    printErrors: false

    function checkNext() {
      if (currentIndex >= 16) {
        return;
      }

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
        Qt.callLater(() => {
          checkNext();
        });
      }
    }

    onLoadFailed: function (error) {
      currentIndex++;
      Qt.callLater(() => {
        checkNext();
      });
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
        Qt.callLater(() => {
          checkNextIntelTemp();
        });
      } else {
        root.cpuTemp = Math.round(parseInt(data) / 1000.0);
      }
    }
    onLoadFailed: function (error) {
      Qt.callLater(() => {
        checkNextIntelTemp();
      });
    }
  }

  FileView {
    id: gpuTempNameReader
    property int currentIndex: 0
    printErrors: false

    function checkNext() {
      if (currentIndex >= 16) {
        if (Settings.systemMonitor.enableDgpuMonitoring) {
          nvidiaSmiCheck.running = true;
        } else {
          root.gpuVramCheckIndex = 0;
          checkNextGpuVram();
        }
        return;
      }

      gpuTempNameReader.path = `/sys/class/hwmon/hwmon${currentIndex}/name`;
      gpuTempNameReader.reload();
    }

    onLoaded: {
      const name = text().trim();
      if (root.supportedTempGpuSensorNames.includes(name)) {
        const hwmonPath = `/sys/class/hwmon/hwmon${currentIndex}`;
        const gpuType = name === "amdgpu" ? "amd" : "intel";
        root.foundGpuSensors.push({
          hwmonPath,
          type: gpuType,
          hasDedicatedVram: false
        });
      }

      currentIndex++;
      Qt.callLater(() => {
        checkNext();
      });
    }

    onLoadFailed: function (error) {
      currentIndex++;
      Qt.callLater(() => {
        checkNext();
      });
    }
  }

  FileView {
    id: gpuTempReader
    printErrors: false

    onLoaded: {
      const data = text().trim();
      root.gpuTemp = Math.round(parseInt(data) / 1000.0);
    }
  }

  Process {
    id: nvidiaSmiCheck
    command: ["sh", "-c", "command -v nvidia-smi"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim().length > 0) {
          root.foundGpuSensors.push({
            hwmonPath: "",
            type: "nvidia",
            hasDedicatedVram: true
          });
        }
        root.gpuVramCheckIndex = 0;
        checkNextGpuVram();
      }
    }
  }

  FileView {
    id: gpuVramChecker
    printErrors: false

    onLoaded: {
      const vramSize = parseInt(text().trim());
      if (vramSize > 0) {
        root.foundGpuSensors[root.gpuVramCheckIndex].hasDedicatedVram = true;
      }
      root.gpuVramCheckIndex++;
      Qt.callLater(() => {
        checkNextGpuVram();
      });
    }

    onLoadFailed: function (error) {
      root.gpuVramCheckIndex++;
      Qt.callLater(() => {
        checkNextGpuVram();
      });
    }
  }

  Process {
    id: nvidiaTempProcess
    command: ["nvidia-smi", "--query-gpu=temperature.gpu", "--format=csv,noheader,nounits"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const temp = parseInt(text.trim());
        if (!isNaN(temp)) {
          root.gpuTemp = temp;
        }
      }
    }
  }

  function parseZfsArcStats(text) {
    if (!text)
      return;
    const lines = text.split("\n");

    let foundSize = false;
    let foundCmin = false;

    for (const line of lines) {
      const parts = line.trim().split(/\s+/);
      if (parts.length >= 3) {
        if (parts[0] === "size") {
          const arcSizeBytes = parseInt(parts[2]) || 0;
          root.zfsArcSizeKb = Math.floor(arcSizeBytes / 1024);
          foundSize = true;
        } else if (parts[0] === "c_min") {
          const arcCminBytes = parseInt(parts[2]) || 0;
          root.zfsArcCminKb = Math.floor(arcCminBytes / 1024);
          foundCmin = true;
        }

        if (foundSize && foundCmin) {
          return;
        }
      }
    }

    if (!foundSize) {
      root.zfsArcSizeKb = 0;
    }
    if (!foundCmin) {
      root.zfsArcCminKb = 0;
    }
  }

  function parseLoadAverage(text) {
    if (!text)
      return;
    const parts = text.trim().split(/\s+/);
    if (parts.length >= 3) {
      root.loadAvg1 = parseFloat(parts[0]);
      root.loadAvg5 = parseFloat(parts[1]);
      root.loadAvg15 = parseFloat(parts[2]);
    }
  }

  function parseMemoryInfo(text) {
    if (!text)
      return;
    const lines = text.split("\n");
    let memTotal = 0;
    let memAvailable = 0;
    let swapTotal = 0;
    let swapFree = 0;

    for (const line of lines) {
      if (line.startsWith("MemTotal:")) {
        memTotal = parseInt(line.split(/\s+/)[1]) || 0;
      } else if (line.startsWith("MemAvailable:")) {
        memAvailable = parseInt(line.split(/\s+/)[1]) || 0;
      } else if (line.startsWith("SwapTotal:")) {
        swapTotal = parseInt(line.split(/\s+/)[1]) || 0;
      } else if (line.startsWith("SwapFree:")) {
        swapFree = parseInt(line.split(/\s+/)[1]) || 0;
      }
    }

    if (memTotal > 0) {
      let usageKb = memTotal - memAvailable;
      if (root.zfsArcSizeKb > 0) {
        usageKb = Math.max(0, usageKb - root.zfsArcSizeKb + root.zfsArcCminKb);
      }
      root.memGb = (usageKb / 1048576).toFixed(1);
      root.memPercent = Math.round((usageKb / memTotal) * 100);
    }

    root.swapTotalGb = (swapTotal / 1048576).toFixed(1);
    if (swapTotal > 0) {
      const swapUsedKb = swapTotal - swapFree;
      root.swapGb = (swapUsedKb / 1048576).toFixed(1);
      root.swapPercent = Math.round((swapUsedKb / swapTotal) * 100);
    } else {
      root.swapGb = 0;
      root.swapPercent = 0;
    }
  }

  function calculateCpuUsage(text) {
    if (!text)
      return;
    const lines = text.split("\n");
    const cpuLine = lines[0];

    if (!cpuLine.startsWith("cpu "))
      return;
    const parts = cpuLine.split(/\s+/);
    const stats = {
      user: parseInt(parts[1]) || 0,
      nice: parseInt(parts[2]) || 0,
      system: parseInt(parts[3]) || 0,
      idle: parseInt(parts[4]) || 0,
      iowait: parseInt(parts[5]) || 0,
      irq: parseInt(parts[6]) || 0,
      softirq: parseInt(parts[7]) || 0,
      steal: parseInt(parts[8]) || 0,
      guest: parseInt(parts[9]) || 0,
      guestNice: parseInt(parts[10]) || 0
    };
    const totalIdle = stats.idle + stats.iowait;
    const total = Object.values(stats).reduce((sum, val) => sum + val, 0);

    if (root.prevCpuStats) {
      const prevTotalIdle = root.prevCpuStats.idle + root.prevCpuStats.iowait;
      const prevTotal = Object.values(root.prevCpuStats).reduce((sum, val) => sum + val, 0);

      const diffTotal = total - prevTotal;
      const diffIdle = totalIdle - prevTotalIdle;

      if (diffTotal > 0) {
        root.cpuUsage = (((diffTotal - diffIdle) / diffTotal) * 100).toFixed(1);
      }
    }

    root.prevCpuStats = stats;
  }

  function calculateNetworkSpeed(text) {
    if (!text) {
      return;
    }

    const currentTime = Date.now() / 1000;
    const lines = text.split("\n");

    let totalRx = 0;
    let totalTx = 0;

    for (let i = 2; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line) {
        continue;
      }

      const colonIndex = line.indexOf(":");
      if (colonIndex === -1) {
        continue;
      }

      const iface = line.substring(0, colonIndex).trim();
      if (iface === "lo") {
        continue;
      }

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

        if (rxDiff < 0) {
          rxDiff = 0;
        }
        if (txDiff < 0) {
          txDiff = 0;
        }

        root.rxSpeed = Math.round(rxDiff / timeDiff);
        root.txSpeed = Math.round(txDiff / timeDiff);

        const now = Date.now();
        if (root.rxSpeed > root.rxMaxSpeed) {
          networkStatsAdapter.rxPeaks = [...(networkStatsAdapter.rxPeaks || []),
            {
              speed: root.rxSpeed,
              timestamp: now
            }
          ];
          networkStatsSaveDebounce.restart();
        }
        if (root.txSpeed > root.txMaxSpeed) {
          networkStatsAdapter.txPeaks = [...(networkStatsAdapter.txPeaks || []),
            {
              speed: root.txSpeed,
              timestamp: now
            }
          ];
          networkStatsSaveDebounce.restart();
        }
      }
    }

    root.prevRxBytes = totalRx;
    root.prevTxBytes = totalTx;
    root.prevTime = currentTime;
  }

  function formatSpeed(bytesPerSecond) {
    const units = ["KB", "MB", "GB"];
    let value = bytesPerSecond / 1024;
    let unitIndex = 0;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    const unit = units[unitIndex];
    const shortUnit = unit[0];
    const numStr = value < 10 ? value.toFixed(1) : Math.round(value).toString();

    return (numStr + unit).length > 5 ? numStr + shortUnit : numStr + unit;
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

  function formatMemoryGb(memGb) {
    const value = parseFloat(memGb);
    if (isNaN(value))
      return "0G";

    if (value < 10)
      return value.toFixed(1) + "G";
    return Math.round(value) + "G";
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
        for (let i = 0; i < root.intelTempValues.length; i++) {
          sum += root.intelTempValues[i];
        }
        root.cpuTemp = Math.round(sum / root.intelTempValues.length);
      } else {
        root.cpuTemp = 0;
      }
      return;
    }

    root.intelTempFilesChecked++;
    cpuTempReader.path = `${root.cpuTempHwmonPath}/temp${root.intelTempFilesChecked}_input`;
    cpuTempReader.reload();
  }

  function checkNextGpuVram() {
    while (root.gpuVramCheckIndex < root.foundGpuSensors.length) {
      const gpu = root.foundGpuSensors[root.gpuVramCheckIndex];
      if (gpu.type === "amd") {
        gpuVramChecker.path = `${gpu.hwmonPath}/device/mem_info_vram_total`;
        gpuVramChecker.reload();
        return;
      }
      root.gpuVramCheckIndex++;
    }

    selectBestGpu();
  }

  function selectBestGpu() {
    if (root.foundGpuSensors.length === 0) {
      return;
    }

    const dgpuEnabled = Settings.systemMonitor.enableDgpuMonitoring;
    let best = null;

    for (let i = 0; i < root.foundGpuSensors.length; i++) {
      const gpu = root.foundGpuSensors[i];

      if (gpu.type === "nvidia") {
        if (dgpuEnabled) {
          best = gpu;
          break;
        }
        continue;
      }

      if (gpu.type === "amd" && gpu.hasDedicatedVram) {
        if (dgpuEnabled) {
          best = gpu;
          break;
        }
        continue;
      }

      if (gpu.type === "intel" && !best) {
        if (dgpuEnabled) {
          best = gpu;
        }
        continue;
      }

      if (gpu.type === "amd" && !gpu.hasDedicatedVram && !best) {
        best = gpu;
      }
    }

    if (best) {
      root.gpuTempHwmonPath = best.hwmonPath;
      root.gpuType = best.type;
      root.gpuAvailable = true;
    }
  }

  function updateGpuTemperature() {
    if (root.gpuType === "nvidia") {
      nvidiaTempProcess.running = true;
    } else if (root.gpuType === "amd" || root.gpuType === "intel") {
      gpuTempReader.path = `${root.gpuTempHwmonPath}/temp1_input`;
      gpuTempReader.reload();
    }
  }
}
