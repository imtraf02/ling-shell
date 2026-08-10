pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.common
import qs.services
import qs.widgets

Item {
  id: root

  property bool active: false
  property var cpuHistory: []
  property var memoryHistory: []
  property var networkHistory: []

  readonly property bool showCpu: Settings.dashboard.performance.showCpu
  readonly property bool showMemory: Settings.dashboard.performance.showMemory
  readonly property bool showGpu: Settings.dashboard.performance.showGpu
  readonly property bool showStorage: Settings.dashboard.performance.showStorage
  readonly property bool showSwap: Settings.dashboard.performance.showSwap
  readonly property bool showNetwork: Settings.dashboard.performance.showNetwork
  readonly property bool showBattery: Settings.dashboard.performance.showBattery && UPower.displayDevice.isLaptopBattery
  readonly property bool hasHeroMetrics: showCpu || showMemory
  readonly property bool hasCompactMetrics: showGpu || showStorage || showSwap || showNetwork || showBattery
  readonly property bool hasMetrics: hasHeroMetrics || hasCompactMetrics

  implicitWidth: 820
  implicitHeight: Math.max(360, Math.min(540, page.implicitHeight))

  function append(history, value) {
    const result = history.slice(Math.max(0, history.length - 59));
    result.push(Math.max(0, Number(value) || 0));
    return result;
  }

  function formatRate(bytes) {
    const value = Math.max(0, Number(bytes) || 0);
    if (value >= 1024 * 1024)
      return (value / 1024 / 1024).toFixed(1) + " MB/s";
    if (value >= 1024)
      return (value / 1024).toFixed(1) + " KB/s";
    return Math.round(value) + " B/s";
  }

  function seedHistory() {
    if (cpuHistory.length > 0)
      return;
    cpuHistory = [SystemUsageService.cpuUsage];
    memoryHistory = [SystemUsageService.memPercent];
    networkHistory = [Math.max(SystemUsageService.rxRatio, SystemUsageService.txRatio) * 100];
  }

  onActiveChanged: {
    if (active)
      seedHistory();
  }

  Connections {
    target: SystemUsageService
    function onCpuUsageChanged() {
      if (!root.active)
        return;
      root.cpuHistory = root.append(root.cpuHistory, SystemUsageService.cpuUsage);
      root.memoryHistory = root.append(root.memoryHistory, SystemUsageService.memPercent);
      root.networkHistory = root.append(root.networkHistory, Math.max(SystemUsageService.rxRatio, SystemUsageService.txRatio) * 100);
    }
  }

  IFlickable {
    anchors.fill: parent
    contentWidth: width
    contentHeight: Math.max(height, page.implicitHeight)
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    ColumnLayout {
      id: page
      width: parent.width
      spacing: Style.spacing.normal

      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        spacing: Style.spacing.normal

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0
          IText {
            Layout.fillWidth: true
            text: "System overview"
            font.pointSize: Style.font.size.large
            font.weight: Font.DemiBold
          }
          IText {
            Layout.fillWidth: true
            text: root.active ? "Live resource usage" : "Monitoring paused"
            color: ThemeService.palette.mOnSurfaceVariant
            font.pointSize: Style.font.size.small
          }
        }

        Rectangle {
          implicitWidth: liveRow.implicitWidth + Style.padding.normal * 2
          implicitHeight: 30
          radius: height / 2
          color: ThemeService.palette.mPrimaryContainer

          RowLayout {
            id: liveRow
            anchors.centerIn: parent
            spacing: Style.spacing.small
            Rectangle {
              Layout.preferredWidth: 7
              Layout.preferredHeight: 7
              radius: width / 2
              color: root.active ? ThemeService.palette.mPrimary : ThemeService.palette.mOutline
            }
            IText {
              text: root.active ? "Live" : "Paused"
              color: ThemeService.palette.mOnPrimaryContainer
              font.pointSize: Style.font.size.small
              font.weight: Font.Medium
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? 182 : 0
        visible: root.hasHeroMetrics
        spacing: Style.spacing.normal

        HeroMetricCard {
          visible: root.showCpu
          title: "CPU"
          icon: "memory"
          value: Math.round(SystemUsageService.cpuUsage) + "%"
          supportingText: SystemUsageService.cpuTemp > 0
            ? Math.round(SystemUsageService.cpuTemp) + "°C · Load " + SystemUsageService.loadAvg1.toFixed(2)
            : "Load " + SystemUsageService.loadAvg1.toFixed(2)
          trailingText: SystemUsageService.nproc > 0 ? SystemUsageService.nproc + " cores" : ""
          percentage: SystemUsageService.cpuUsage
          accent: SystemUsageService.cpuColor
          history: root.cpuHistory
        }

        HeroMetricCard {
          visible: root.showMemory
          title: "Memory"
          icon: "developer_board"
          value: SystemUsageService.memGb.toFixed(1) + " GB"
          supportingText: Math.round(SystemUsageService.memPercent) + "% of memory in use"
          trailingText: Math.round(SystemUsageService.memPercent) + "%"
          percentage: SystemUsageService.memPercent
          accent: SystemUsageService.memColor
          history: root.memoryHistory
        }
      }

      GridLayout {
        id: compactGrid
        Layout.fillWidth: true
        visible: root.hasCompactMetrics
        columns: width >= 700 ? 3 : (width >= 440 ? 2 : 1)
        columnSpacing: Style.spacing.normal
        rowSpacing: Style.spacing.normal

        CompactMetricCard {
          visible: root.showGpu
          label: "GPU"
          icon: "videogame_asset"
          value: SystemUsageService.gpuAvailable ? Math.round(SystemUsageService.gpuTemp) + "°C" : "Unavailable"
          detail: SystemUsageService.gpuAvailable ? (SystemUsageService.gpuType || "Detected GPU") : "No supported sensor"
          percentage: SystemUsageService.gpuAvailable ? Math.min(100, SystemUsageService.gpuTemp) : 0
          accent: SystemUsageService.gpuAvailable ? SystemUsageService.gpuColor : ThemeService.palette.mOutline
        }

        CompactMetricCard {
          visible: root.showStorage
          label: "Storage"
          icon: "hard_drive"
          value: Math.round(SystemUsageService.diskPercents["/"] || 0) + "%"
          detail: (SystemUsageService.diskUsedGb["/"] || 0).toFixed(1) + " of " + (SystemUsageService.diskSizeGb["/"] || 0).toFixed(1) + " GB"
          percentage: SystemUsageService.diskPercents["/"] || 0
          accent: SystemUsageService.getDiskColor("/")
        }

        CompactMetricCard {
          visible: root.showSwap
          label: "Swap"
          icon: "swap_horiz"
          value: SystemUsageService.swapTotalGb > 0 ? SystemUsageService.swapGb.toFixed(1) + " GB" : "Off"
          detail: SystemUsageService.swapTotalGb > 0 ? Math.round(SystemUsageService.swapPercent) + "% in use" : "Not configured"
          percentage: SystemUsageService.swapPercent
          accent: SystemUsageService.swapTotalGb > 0 ? SystemUsageService.swapColor : ThemeService.palette.mOutline
        }

        CompactMetricCard {
          visible: root.showNetwork
          label: "Network"
          icon: "network_check"
          value: root.formatRate(SystemUsageService.rxSpeed)
          detail: "Up " + root.formatRate(SystemUsageService.txSpeed)
          percentage: Math.max(SystemUsageService.rxRatio, SystemUsageService.txRatio) * 100
          accent: ThemeService.palette.mSecondary
        }

        CompactMetricCard {
          visible: root.showBattery
          label: "Battery"
          icon: "battery_full"
          value: Math.round(UPower.displayDevice.percentage * 100) + "%"
          detail: UPower.onBattery ? "On battery" : "Connected to power"
          percentage: UPower.displayDevice.percentage * 100
          accent: ThemeService.palette.mTertiary
        }
      }

      DashboardCard {
        Layout.fillWidth: true
        Layout.preferredHeight: 180
        visible: !root.hasMetrics
        cardColor: ThemeService.palette.mSurfaceContainerHigh

        ColumnLayout {
          anchors.centerIn: parent
          width: Math.min(parent.width, 360)
          spacing: Style.spacing.small
          IIcon {
            Layout.alignment: Qt.AlignHCenter
            icon: "monitoring"
            color: ThemeService.palette.mPrimary
            font.pointSize: Style.font.size.extraLarge * 1.5
          }
          IText {
            Layout.fillWidth: true
            text: "No performance cards enabled"
            horizontalAlignment: Text.AlignHCenter
            font.weight: Font.DemiBold
          }
          IText {
            Layout.fillWidth: true
            text: "Choose the metrics you want to see in Dashboard settings."
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: ThemeService.palette.mOnSurfaceVariant
            font.pointSize: Style.font.size.small
          }
        }
      }
    }
  }

  component HeroMetricCard: DashboardCard {
    id: heroCard

    property string value: ""
    property string supportingText: ""
    property string trailingText: ""
    property real percentage: 0
    property color accent: ThemeService.palette.mPrimary
    property var history: []

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    Layout.fillHeight: true
    cardColor: ThemeService.palette.mSurfaceContainerHigh

    ColumnLayout {
      anchors.fill: parent
      spacing: Style.spacing.small

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.spacing.small
        IText {
          text: heroCard.value
          color: heroCard.accent
          font.pointSize: Style.font.size.extraLarge
          font.weight: Font.Bold
        }
        Item { Layout.fillWidth: true }
        IText {
          visible: heroCard.trailingText !== ""
          text: heroCard.trailingText
          color: ThemeService.palette.mOnSurfaceVariant
          font.pointSize: Style.font.size.small
          font.weight: Font.Medium
        }
      }

      IText {
        Layout.fillWidth: true
        text: heroCard.supportingText
        color: ThemeService.palette.mOnSurfaceVariant
        font.pointSize: Style.font.size.small
        elide: Text.ElideRight
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 54
        radius: Style.rounding.small
        color: ThemeService.palette.mSurfaceContainer
        clip: true

        HistoryChart {
          anchors.fill: parent
          anchors.margins: Style.padding.small
          values: heroCard.history
          lineColor: heroCard.accent
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 5
        radius: height / 2
        color: ThemeService.palette.mSurfaceVariant
        Rectangle {
          width: parent.width * Math.max(0, Math.min(100, heroCard.percentage)) / 100
          height: parent.height
          radius: height / 2
          color: heroCard.accent
        }
      }
    }
  }

  component CompactMetricCard: DashboardCard {
    id: compactCard

    property string label: ""
    property string value: ""
    property string detail: ""
    property real percentage: 0
    property color accent: ThemeService.palette.mPrimary

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    Layout.preferredHeight: 118
    cardColor: ThemeService.palette.mSurfaceContainer

    ColumnLayout {
      anchors.fill: parent
      spacing: Style.spacing.small

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.spacing.small

        Rectangle {
          Layout.preferredWidth: 34
          Layout.preferredHeight: 34
          radius: height / 2
          color: ThemeService.palette.mSurfaceVariant
          IIcon {
            anchors.centerIn: parent
            icon: compactCard.icon
            color: compactCard.accent
            font.pointSize: Style.font.size.large
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.minimumWidth: 0
          spacing: 0
          IText {
            Layout.fillWidth: true
            text: compactCard.label
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }
          IText {
            Layout.fillWidth: true
            text: compactCard.detail
            color: ThemeService.palette.mOnSurfaceVariant
            font.pointSize: Style.font.size.small
            elide: Text.ElideRight
          }
        }

        IText {
          text: compactCard.value
          color: compactCard.accent
          font.pointSize: Style.font.size.large
          font.weight: Font.Bold
        }
      }

      Item { Layout.fillHeight: true }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 5
        radius: height / 2
        color: ThemeService.palette.mSurfaceVariant
        Rectangle {
          width: parent.width * Math.max(0, Math.min(100, compactCard.percentage)) / 100
          height: parent.height
          radius: height / 2
          color: compactCard.accent
        }
      }
    }
  }
}
