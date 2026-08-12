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
  readonly property bool hasUtilityMetrics: showGpu || showStorage || showSwap
  readonly property bool hasDetailMetrics: showNetwork || showBattery
  readonly property bool hasMetrics: hasHeroMetrics || hasUtilityMetrics || hasDetailMetrics

  implicitWidth: 872
  implicitHeight: 660

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

  DashboardCard {
    anchors.fill: parent
    cardColor: ThemeService.palette.mSurfaceContainer
    border.width: 1
    border.color: Qt.alpha(ThemeService.palette.mOutline, 0.22)

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
          Layout.preferredHeight: 64
          spacing: Style.spacing.normal

          ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 0

            IText {
              Layout.fillWidth: true
              text: "System overview"
              font.pointSize: Style.font.size.extraLarge
              font.weight: Font.Bold
              elide: Text.ElideRight
            }

            IText {
              Layout.fillWidth: true
              text: root.active ? "Live resource usage" : "Monitoring paused"
              color: ThemeService.palette.mOnSurfaceVariant
              font.pointSize: Style.font.size.larger
              elide: Text.ElideRight
            }
          }

          Rectangle {
            implicitWidth: liveRow.implicitWidth + Style.padding.large * 2
            implicitHeight: 38
            radius: height / 2
            color: Qt.alpha(ThemeService.palette.mPrimary, 0.08)
            border.width: 1
            border.color: root.active ? Qt.alpha(ThemeService.palette.mPrimary, 0.65) : Qt.alpha(ThemeService.palette.mOutline, 0.3)

            RowLayout {
              id: liveRow
              anchors.centerIn: parent
              spacing: Style.spacing.small

              Rectangle {
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: width / 2
                color: root.active ? ThemeService.palette.mPrimary : ThemeService.palette.mOutline
              }

              IText {
                text: root.active ? "Live" : "Paused"
                color: root.active ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurfaceVariant
                font.pointSize: Style.font.size.larger
                font.weight: Font.DemiBold
              }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: visible ? 214 : 0
          visible: root.hasHeroMetrics
          spacing: Style.spacing.normal

          HeroMetricCard {
            visible: root.showCpu
            label: "CPU"
            icon: "memory"
            value: Math.round(SystemUsageService.cpuUsage) + "%"
            supportingText: SystemUsageService.cpuTemp > 0 ? Math.round(SystemUsageService.cpuTemp) + "°C · Load " + SystemUsageService.loadAvg1.toFixed(2) : "Load " + SystemUsageService.loadAvg1.toFixed(2)
            trailingText: SystemUsageService.nproc > 0 ? SystemUsageService.nproc + " cores" : ""
            percentage: SystemUsageService.cpuUsage
            accent: SystemUsageService.cpuColor
            history: root.cpuHistory
            showHistory: true
          }

          HeroMetricCard {
            visible: root.showMemory
            label: "Memory"
            icon: "developer_board"
            value: SystemUsageService.memGb.toFixed(1) + " GB"
            supportingText: Math.round(SystemUsageService.memPercent) + "% of memory in use"
            trailingText: Math.round(SystemUsageService.memPercent) + "%"
            percentage: SystemUsageService.memPercent
            accent: SystemUsageService.memColor
          }
        }

        GridLayout {
          id: utilityGrid
          Layout.fillWidth: true
          visible: root.hasUtilityMetrics
          columns: width >= 700 ? 3 : 1
          columnSpacing: Style.spacing.normal
          rowSpacing: Style.spacing.normal

          CompactMetricCard {
            visible: root.showGpu
            label: "GPU"
            icon: "videogame_asset"
            stackValue: true
            value: SystemUsageService.gpuAvailable ? Math.round(SystemUsageService.gpuTemp) + "°C" : "Unavailable"
            detail: SystemUsageService.gpuAvailable ? (SystemUsageService.gpuType || "Detected GPU") : "No supported GPU"
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
        }

        GridLayout {
          id: detailGrid
          Layout.fillWidth: true
          visible: root.hasDetailMetrics
          columns: width >= 560 ? 2 : 1
          columnSpacing: Style.spacing.normal
          rowSpacing: Style.spacing.normal

          DetailMetricCard {
            visible: root.showNetwork
            label: "Network"
            icon: "network_check"
            value: root.formatRate(SystemUsageService.rxSpeed)
            detail: "Up " + root.formatRate(SystemUsageService.txSpeed)
            percentage: Math.max(SystemUsageService.rxRatio, SystemUsageService.txRatio) * 100
            accent: ThemeService.palette.mSecondary
            history: root.networkHistory
            showHistory: true
          }

          DetailMetricCard {
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
          Layout.preferredHeight: 210
          visible: !root.hasMetrics
          cardColor: ThemeService.palette.mSurfaceContainerHigh
          border.width: 1
          border.color: Qt.alpha(ThemeService.palette.mOutline, 0.22)

          ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width, 360)
            spacing: Style.spacing.small

            Rectangle {
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredWidth: 56
              Layout.preferredHeight: 56
              radius: Style.rounding.small
              color: Qt.alpha(ThemeService.palette.mPrimary, 0.1)

              IIcon {
                anchors.centerIn: parent
                icon: "monitoring"
                color: ThemeService.palette.mPrimary
                font.pointSize: Style.font.size.extraLarge
              }
            }

            IText {
              Layout.fillWidth: true
              text: "No performance cards enabled"
              horizontalAlignment: Text.AlignHCenter
              font.weight: Font.DemiBold
              font.pointSize: Style.font.size.larger
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
  }

  component HeroMetricCard: DashboardCard {
    id: heroCard

    property string label: ""
    property string value: ""
    property string supportingText: ""
    property string trailingText: ""
    property real percentage: 0
    property color accent: ThemeService.palette.mPrimary
    property var history: []
    property bool showHistory: false

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    Layout.fillHeight: true
    cardColor: ThemeService.palette.mSurfaceContainerHigh
    border.width: 1
    border.color: Qt.alpha(ThemeService.palette.mOutline, 0.22)

    ColumnLayout {
      anchors.fill: parent
      spacing: Style.spacing.small

      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        spacing: Style.spacing.normal

        Rectangle {
          Layout.preferredWidth: 40
          Layout.preferredHeight: 40
          radius: Style.rounding.small
          color: Qt.alpha(heroCard.accent, 0.1)
          border.width: 1
          border.color: Qt.alpha(heroCard.accent, 0.28)

          IIcon {
            anchors.centerIn: parent
            icon: heroCard.icon
            color: heroCard.accent
            font.pointSize: Style.font.size.large
          }
        }

        IText {
          Layout.fillWidth: true
          text: heroCard.label
          font.pointSize: Style.font.size.larger
          font.weight: Font.DemiBold
          elide: Text.ElideRight
        }

        IText {
          visible: heroCard.trailingText !== ""
          text: heroCard.trailingText
          color: ThemeService.palette.mOnSurfaceVariant
          font.pointSize: Style.font.size.larger
          font.weight: Font.Medium
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 0
        spacing: Style.spacing.normal

        ColumnLayout {
          Layout.fillWidth: !heroCard.showHistory
          Layout.preferredWidth: heroCard.showHistory ? 150 : -1
          Layout.minimumWidth: 0
          spacing: 0

          Item {
            Layout.fillHeight: true
          }

          IText {
            Layout.fillWidth: true
            text: heroCard.value
            color: ThemeService.palette.mOnSurface
            font.pointSize: Style.font.size.extraLarge * 1.35
            font.weight: Font.Bold
            animate: true
            animateDuration: 200
            elide: Text.ElideRight
          }

          IText {
            Layout.fillWidth: true
            text: heroCard.supportingText
            color: ThemeService.palette.mOnSurfaceVariant
            font.pointSize: Style.font.size.small
            elide: Text.ElideRight
          }

          Item {
            Layout.fillHeight: true
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.minimumWidth: 150
          Layout.minimumHeight: 70
          visible: heroCard.showHistory
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
      }

      MetricProgressBar {
        Layout.fillWidth: true
        percentage: heroCard.percentage
        accent: heroCard.accent
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
    property bool stackValue: false

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    Layout.preferredHeight: 148
    cardColor: ThemeService.palette.mSurfaceContainerHigh
    border.width: 1
    border.color: Qt.alpha(ThemeService.palette.mOutline, 0.22)

    ColumnLayout {
      anchors.fill: parent
      spacing: Style.spacing.small

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.spacing.normal

        Rectangle {
          Layout.preferredWidth: 40
          Layout.preferredHeight: 40
          radius: Style.rounding.small
          color: Qt.alpha(compactCard.accent, 0.1)
          border.width: 1
          border.color: Qt.alpha(compactCard.accent, 0.22)

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
            font.pointSize: Style.font.size.larger
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }

          IText {
            Layout.fillWidth: true
            visible: !compactCard.stackValue
            text: compactCard.detail
            color: ThemeService.palette.mOnSurfaceVariant
            font.pointSize: Style.font.size.small
            elide: Text.ElideRight
          }
        }

        IText {
          visible: !compactCard.stackValue
          Layout.maximumWidth: compactCard.width * 0.42
          text: compactCard.value
          color: ThemeService.palette.mOnSurface
          font.pointSize: Style.font.size.large
          font.weight: Font.Bold
          animate: true
          animateDuration: 200
          elide: Text.ElideRight
        }
      }

      IText {
        Layout.fillWidth: true
        Layout.leftMargin: 52
        visible: compactCard.stackValue
        text: compactCard.value
        color: ThemeService.palette.mOnSurface
        font.pointSize: Style.font.size.larger
        font.weight: Font.Bold
        animate: true
        animateDuration: 200
        elide: Text.ElideRight
      }

      IText {
        Layout.fillWidth: true
        Layout.leftMargin: 52
        visible: compactCard.stackValue
        text: compactCard.detail
        color: ThemeService.palette.mOnSurfaceVariant
        font.pointSize: Style.font.size.small
        elide: Text.ElideRight
      }

      Item {
        Layout.fillHeight: true
      }

      MetricProgressBar {
        Layout.fillWidth: true
        percentage: compactCard.percentage
        accent: compactCard.accent
      }
    }
  }

  component DetailMetricCard: DashboardCard {
    id: detailCard

    property string label: ""
    property string value: ""
    property string detail: ""
    property real percentage: 0
    property color accent: ThemeService.palette.mPrimary
    property var history: []
    property bool showHistory: false

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    Layout.preferredHeight: 178
    cardColor: ThemeService.palette.mSurfaceContainerHigh
    border.width: 1
    border.color: Qt.alpha(ThemeService.palette.mOutline, 0.22)

    ColumnLayout {
      anchors.fill: parent
      spacing: Style.spacing.small

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.spacing.normal

        Rectangle {
          Layout.preferredWidth: 40
          Layout.preferredHeight: 40
          radius: Style.rounding.small
          color: Qt.alpha(detailCard.accent, 0.1)
          border.width: 1
          border.color: Qt.alpha(detailCard.accent, 0.22)

          IIcon {
            anchors.centerIn: parent
            icon: detailCard.icon
            color: detailCard.accent
            font.pointSize: Style.font.size.large
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.minimumWidth: 0
          spacing: 0

          IText {
            Layout.fillWidth: true
            text: detailCard.label
            font.pointSize: Style.font.size.larger
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }

          IText {
            Layout.fillWidth: true
            text: detailCard.detail
            color: ThemeService.palette.mOnSurfaceVariant
            font.pointSize: Style.font.size.small
            elide: Text.ElideRight
          }
        }

        IText {
          Layout.maximumWidth: detailCard.width * 0.42
          text: detailCard.value
          color: ThemeService.palette.mOnSurface
          font.pointSize: Style.font.size.extraLarge
          font.weight: Font.Bold
          animate: true
          animateDuration: 200
          elide: Text.ElideRight
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 70
        visible: detailCard.showHistory
        radius: Style.rounding.small
        color: ThemeService.palette.mSurfaceContainer
        clip: true

        HistoryChart {
          anchors.fill: parent
          anchors.margins: Style.padding.small
          values: detailCard.history
          lineColor: detailCard.accent
        }
      }

      Item {
        Layout.fillHeight: true
        visible: !detailCard.showHistory
      }

      MetricProgressBar {
        Layout.fillWidth: true
        visible: !detailCard.showHistory
        percentage: detailCard.percentage
        accent: detailCard.accent
      }
    }
  }

  component MetricProgressBar: Rectangle {
    id: progressBar

    property real percentage: 0
    property color accent: ThemeService.palette.mPrimary

    implicitHeight: 7
    radius: height / 2
    color: ThemeService.palette.mSurfaceVariant
    border.width: 1
    border.color: Qt.alpha(ThemeService.palette.mOutline, 0.12)
    clip: true

    Rectangle {
      width: parent.width * Math.max(0, Math.min(100, progressBar.percentage)) / 100
      height: parent.height
      radius: height / 2
      color: progressBar.accent

      Behavior on width {
        NumberAnimation {
          duration: 180
          easing.type: Easing.OutQuint
        }
      }
    }
  }
}
