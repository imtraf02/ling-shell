import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

ColumnLayout {
  spacing: Style.spacing.normal
  SettingsPage {
    title: "System & Lock"
    description: "Session behavior, lock-screen authentication, and resource thresholds."
    icon: "lock"
    sectionId: "system"
    SettingsCardGrid {
      id: grid
      SettingsCard {
        title: "Session"
        description: "Session panel and keyboard behavior."
        icon: "logout"
        ITextInput { label: "Session illustration"; text: Settings.session.gif; onEditingFinished: Settings.session.gif = text }
        SettingsSpinRow { label: "Drag threshold"; value: Settings.session.dragThreshold; from: 0; to: 200; suffix: " px"; onChanged: value => Settings.session.dragThreshold = value }
        IToggle { label: "Vim keybinds"; checked: Settings.session.vimKeybinds; onToggled: checked => Settings.session.vimKeybinds = checked }
      }
      SettingsCard {
        title: "Lock screen"
        description: "Fingerprint authentication and logo treatment."
        icon: "fingerprint"
        IToggle { label: "Recolor logo"; checked: Settings.lock.recolourLogo; onToggled: checked => Settings.lock.recolourLogo = checked }
        IToggle { label: "Enable fingerprint"; checked: Settings.lock.enableFprint; onToggled: checked => Settings.lock.enableFprint = checked }
        SettingsSpinRow { label: "Maximum fingerprint tries"; value: Settings.lock.maxFprintTries; from: 1; to: 10; enabled: Settings.lock.enableFprint; onChanged: value => Settings.lock.maxFprintTries = value }
      }
      SettingsCard {
        title: "System monitor thresholds"
        description: "Warning and critical limits used by the lock-screen monitor."
        icon: "monitor_heart"
        Layout.columnSpan: grid.columns
        GridLayout {
          Layout.fillWidth: true
          columns: width >= 760 ? 3 : 1
          columnSpacing: Style.spacing.small; rowSpacing: Style.spacing.small
          ThresholdBlock { title: "CPU"; warning: Settings.systemMonitor.cpuWarningThreshold; critical: Settings.systemMonitor.cpuCriticalThreshold; onWarningEdited: value => Settings.systemMonitor.cpuWarningThreshold = value; onCriticalEdited: value => Settings.systemMonitor.cpuCriticalThreshold = value }
          ThresholdBlock { title: "Temperature"; suffix: " °C"; maximum: 120; warning: Settings.systemMonitor.tempWarningThreshold; critical: Settings.systemMonitor.tempCriticalThreshold; onWarningEdited: value => Settings.systemMonitor.tempWarningThreshold = value; onCriticalEdited: value => Settings.systemMonitor.tempCriticalThreshold = value }
          ThresholdBlock { title: "GPU"; warning: Settings.systemMonitor.gpuWarningThreshold; critical: Settings.systemMonitor.gpuCriticalThreshold; onWarningEdited: value => Settings.systemMonitor.gpuWarningThreshold = value; onCriticalEdited: value => Settings.systemMonitor.gpuCriticalThreshold = value }
          ThresholdBlock { title: "Memory"; warning: Settings.systemMonitor.memWarningThreshold; critical: Settings.systemMonitor.memCriticalThreshold; onWarningEdited: value => Settings.systemMonitor.memWarningThreshold = value; onCriticalEdited: value => Settings.systemMonitor.memCriticalThreshold = value }
          ThresholdBlock { title: "Swap"; warning: Settings.systemMonitor.swapWarningThreshold; critical: Settings.systemMonitor.swapCriticalThreshold; onWarningEdited: value => Settings.systemMonitor.swapWarningThreshold = value; onCriticalEdited: value => Settings.systemMonitor.swapCriticalThreshold = value }
          ThresholdBlock { title: "Disk"; warning: Settings.systemMonitor.diskWarningThreshold; critical: Settings.systemMonitor.diskCriticalThreshold; onWarningEdited: value => Settings.systemMonitor.diskWarningThreshold = value; onCriticalEdited: value => Settings.systemMonitor.diskCriticalThreshold = value }
        }
      }
      SettingsCard {
        title: "System monitor advanced"
        description: "Polling, GPU, colors, and external monitor behavior."
        icon: "tune"
        advanced: true
        Layout.columnSpan: grid.columns
        SettingsSpinRow { label: "CPU polling interval"; value: Settings.systemMonitor.cpuPollingInterval; from: 500; to: 60000; stepSize: 500; suffix: " ms"; onChanged: value => Settings.systemMonitor.cpuPollingInterval = value }
        SettingsSpinRow { label: "Load average polling interval"; value: Settings.systemMonitor.loadAvgPollingInterval; from: 500; to: 60000; stepSize: 500; suffix: " ms"; onChanged: value => Settings.systemMonitor.loadAvgPollingInterval = value }
        SettingsSpinRow { label: "Temperature polling interval"; value: Settings.systemMonitor.tempPollingInterval; from: 500; to: 60000; stepSize: 500; suffix: " ms"; onChanged: value => Settings.systemMonitor.tempPollingInterval = value }
        SettingsSpinRow { label: "GPU polling interval"; value: Settings.systemMonitor.gpuPollingInterval; from: 500; to: 60000; stepSize: 500; suffix: " ms"; onChanged: value => Settings.systemMonitor.gpuPollingInterval = value }
        SettingsSpinRow { label: "Memory polling interval"; value: Settings.systemMonitor.memPollingInterval; from: 500; to: 60000; stepSize: 500; suffix: " ms"; onChanged: value => Settings.systemMonitor.memPollingInterval = value }
        SettingsSpinRow { label: "Disk polling interval"; value: Settings.systemMonitor.diskPollingInterval; from: 500; to: 60000; stepSize: 500; suffix: " ms"; onChanged: value => Settings.systemMonitor.diskPollingInterval = value }
        SettingsSpinRow { label: "Network polling interval"; value: Settings.systemMonitor.networkPollingInterval; from: 500; to: 60000; stepSize: 500; suffix: " ms"; onChanged: value => Settings.systemMonitor.networkPollingInterval = value }
        IToggle { label: "Monitor discrete GPU"; checked: Settings.systemMonitor.enableDgpuMonitoring; onToggled: checked => Settings.systemMonitor.enableDgpuMonitoring = checked }
        IToggle { label: "Use custom warning colors"; checked: Settings.systemMonitor.useCustomColors; onToggled: checked => Settings.systemMonitor.useCustomColors = checked }
        ITextInput { visible: Settings.systemMonitor.useCustomColors; label: "Warning color"; text: Settings.systemMonitor.warningColor; placeholderText: "#rrggbb"; onEditingFinished: Settings.systemMonitor.warningColor = text }
        ITextInput { visible: Settings.systemMonitor.useCustomColors; label: "Critical color"; text: Settings.systemMonitor.criticalColor; placeholderText: "#rrggbb"; onEditingFinished: Settings.systemMonitor.criticalColor = text }
        ITextInput { label: "External monitor command"; text: Settings.systemMonitor.externalMonitor; onEditingFinished: Settings.systemMonitor.externalMonitor = text }
      }
    }
  }

  component ThresholdBlock: IBox {
    id: threshold
    property string title: ""
    property string suffix: "%"
    property real maximum: 100
    property real warning: 80
    property real critical: 90
    signal warningEdited(real value)
    signal criticalEdited(real value)
    Layout.fillWidth: true
    implicitHeight: thresholdLayout.implicitHeight + Style.padding.small * 2
    color: ThemeService.palette.mSurfaceVariant
    ColumnLayout {
      id: thresholdLayout
      anchors.fill: parent; anchors.margins: Style.padding.small
      IText { text: threshold.title; font.weight: Font.Medium }
      SettingsSpinRow { label: "Warning"; value: threshold.warning; from: 1; to: threshold.maximum; suffix: threshold.suffix; onChanged: value => threshold.warningEdited(value) }
      SettingsSpinRow { label: "Critical"; value: threshold.critical; from: 1; to: threshold.maximum; suffix: threshold.suffix; onChanged: value => threshold.criticalEdited(value) }
    }
  }
}
