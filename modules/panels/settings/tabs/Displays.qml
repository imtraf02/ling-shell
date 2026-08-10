import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.utils
import qs.widgets

ColumnLayout {
  id: root
  spacing: Style.spacing.normal
  Component.onCompleted: {
    ProgramCheckerService.ensure("ddcutilAvailable");
    ProgramCheckerService.ensure("mpvpaperAvailable");
    ProgramCheckerService.ensure("mpvAvailable");
  }

  SettingsPage {
    title: "Displays & Wallpaper"
    description: "Wallpaper sources, monitor assignments, rendering, and brightness."
    icon: "wallpaper"
    sectionId: "display"

    SettingsCardGrid {
      id: grid
      SettingsCard {
        title: "Wallpaper preview"
        description: "Current fallback image and rendering state."
        icon: "image"
        Layout.columnSpan: grid.columns
        IBox {
          Layout.fillWidth: true
          implicitHeight: 96
          color: ThemeService.palette.mSurfaceVariant
          RowLayout {
            anchors.fill: parent; anchors.margins: Style.padding.normal; spacing: Style.spacing.normal
            IIcon { icon: "wallpaper"; font.pointSize: Style.font.size.extraLarge; color: ThemeService.palette.mPrimary }
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1
              IText { text: Settings.wallpaper.enabled ? "Wallpaper enabled" : "Wallpaper disabled"; font.weight: Font.Medium }
              IText { Layout.fillWidth: true; text: Settings.wallpaper.defaultWallpaper || "No fallback wallpaper selected"; elide: Text.ElideMiddle; color: ThemeService.palette.mOnSurfaceVariant; font.pointSize: Style.font.size.small }
            }
            Rectangle { implicitWidth: 10; implicitHeight: 52; radius: Style.rounding.full; color: Settings.wallpaper.enabled ? ThemeService.palette.mPrimary : ThemeService.palette.mOutline }
          }
        }
      }
      SettingsCard {
        title: "Wallpaper source"
        description: "Choose where wallpapers are found."
        icon: "folder_open"
        Layout.columnSpan: grid.columns
        IToggle { label: "Enable wallpaper"; checked: Settings.wallpaper.enabled; onToggled: checked => Settings.wallpaper.enabled = checked }
        IToggle { label: "Enable overview wallpaper"; enabled: Settings.wallpaper.enabled; checked: Settings.wallpaper.overviewEnabled; onToggled: checked => Settings.wallpaper.overviewEnabled = checked }
        ITextInputButton { label: "Wallpaper directory"; text: Settings.wallpaper.directory; buttonIcon: "folder_open"; onInputEditingFinished: Settings.wallpaper.directory = text; onButtonClicked: directoryPicker.openFilePicker() }
        ITextInputButton { label: "Fallback wallpaper"; text: Settings.wallpaper.defaultWallpaper; buttonIcon: "image"; onInputEditingFinished: Settings.wallpaper.defaultWallpaper = text; onButtonClicked: wallpaperPicker.openFilePicker() }
        IToggle { label: "Search subdirectories"; checked: Settings.wallpaper.recursiveSearch; onToggled: checked => Settings.wallpaper.recursiveSearch = checked }
        IToggle { label: "Set selected wallpaper on every monitor"; checked: Settings.wallpaper.setWallpaperOnAllMonitors; onToggled: checked => Settings.wallpaper.setWallpaperOnAllMonitors = checked }
        IFilePicker { id: directoryPicker; title: "Select wallpaper directory"; selectionMode: "folders"; initialPath: FileUtils.trimFileProtocol(Settings.wallpaper.directory); onAccepted: paths => { if (paths.length > 0) Settings.wallpaper.directory = paths[0]; } }
        IFilePicker { id: wallpaperPicker; title: "Select fallback wallpaper"; selectionMode: "files"; initialPath: FileUtils.trimFileProtocol(Settings.wallpaper.directory); nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.pnm", "*.bmp"]; onAccepted: paths => { if (paths.length > 0) Settings.wallpaper.defaultWallpaper = paths[0]; } }
      }
      SettingsCard {
        title: "Live wallpaper"
        description: "Video playback is handled by mpvpaper; the first frame also powers overview and dynamic colors."
        icon: "movie"
        Layout.columnSpan: grid.columns
        badge: LiveWallpaperService.available ? "Ready" : (ProgramCheckerService.isChecked("mpvpaperAvailable") && ProgramCheckerService.isChecked("mpvAvailable") ? "Unavailable" : "Checking")
        SettingsNotice { visible: ProgramCheckerService.isChecked("mpvpaperAvailable") && ProgramCheckerService.isChecked("mpvAvailable") && !LiveWallpaperService.available; warning: true; icon: "extension_off"; text: "mpvpaper and mpv are required. Add both to extraRuntimePackages, then reload Ling Shell." }
        IText { Layout.fillWidth: true; text: "Choose a video from the launcher: > Live Wallpaper. It uses the same wallpaper directory and monitor rules."; wrapMode: Text.WordWrap; color: ThemeService.palette.mOnSurfaceVariant; font.pointSize: Style.font.size.small }
        Repeater {
          model: Quickshell.screens
          delegate: IBox {
            required property ShellScreen modelData
            readonly property string livePath: LiveWallpaperService.getLiveWallpaper(modelData.name)
            Layout.fillWidth: true
            implicitHeight: liveRow.implicitHeight + Style.padding.small * 2
            color: ThemeService.palette.mSurfaceVariant
            RowLayout {
              id: liveRow
              anchors.fill: parent; anchors.margins: Style.padding.small; spacing: Style.spacing.small
              IIcon { icon: livePath ? "movie" : "image"; color: livePath ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurfaceVariant }
              ColumnLayout {
                Layout.fillWidth: true; spacing: 1
                IText { text: modelData.name; font.weight: Font.Medium }
                IText { Layout.fillWidth: true; text: livePath || "Using static wallpaper"; elide: Text.ElideMiddle; color: ThemeService.palette.mOnSurfaceVariant; font.pointSize: Style.font.size.small }
              }
              IButton { visible: livePath !== ""; text: "Use static"; icon: "image"; outlined: true; fontSize: Style.font.size.small; onClicked: LiveWallpaperService.clearLiveWallpaper(modelData.name) }
            }
          }
        }
      }
      SettingsCard {
        title: "Rendering"
        description: "Image fit and transition treatment."
        icon: "tune"
        SettingsChoiceGroup { label: "Fill mode"; currentKey: Settings.wallpaper.fillMode; model: [{ key: "crop", name: "Crop", icon: "crop" }, { key: "fit", name: "Fit", icon: "fit_screen" }, { key: "stretch", name: "Stretch", icon: "open_in_full" }]; onSelected: key => Settings.wallpaper.fillMode = key }
        ITextInput { label: "Fill color"; text: Settings.wallpaper.fillColor; placeholderText: "#000000"; onEditingFinished: Settings.wallpaper.fillColor = text }
        SettingsSpinRow { label: "Transition duration"; value: Settings.wallpaper.transitionDuration; from: 0; to: 5000; stepSize: 50; suffix: " ms"; onChanged: value => Settings.wallpaper.transitionDuration = value }
        SettingsSpinRow { label: "Edge smoothness"; value: Settings.wallpaper.transitionEdgeSmoothness; from: 0; to: 1; stepSize: 0.01; onChanged: value => Settings.wallpaper.transitionEdgeSmoothness = value }
      }
      SettingsCard {
        title: "Brightness"
        description: "Built-in and optional external-display controls."
        icon: "brightness_6"
        SettingsSpinRow { label: "Brightness step"; value: Settings.brightness.brightnessStep; from: 1; to: 25; suffix: "%"; onChanged: value => Settings.brightness.brightnessStep = value }
        IToggle { label: "Enforce minimum brightness"; checked: Settings.brightness.enforceMinimum; onToggled: checked => Settings.brightness.enforceMinimum = checked }
        IToggle { label: "External brightness support"; checked: Settings.brightness.enableDdcSupport; onToggled: checked => Settings.brightness.enableDdcSupport = checked }
        SettingsNotice { visible: Settings.brightness.enableDdcSupport && ProgramCheckerService.isChecked("ddcutilAvailable") && !ProgramCheckerService.ddcutilAvailable; warning: true; icon: "extension_off"; text: "ddcutil is unavailable. Add it to extraRuntimePackages to control external displays." }
      }
      SettingsCard {
        title: "Per-monitor wallpaper"
        description: "Assign sources and images independently for each output."
        icon: "desktop_windows"
        advanced: true
        Layout.columnSpan: grid.columns
        IToggle { label: "Use a directory per monitor"; checked: Settings.wallpaper.enableMultiMonitorDirectories; onToggled: checked => Settings.wallpaper.enableMultiMonitorDirectories = checked }
        Repeater {
          model: Quickshell.screens
          delegate: IBox {
            required property ShellScreen modelData
            visible: Settings.wallpaper.enableMultiMonitorDirectories
            Layout.fillWidth: true
            implicitHeight: monitorFields.implicitHeight + Style.padding.small * 2
            color: ThemeService.palette.mSurfaceVariant
            ColumnLayout {
              id: monitorFields
              anchors.fill: parent; anchors.margins: Style.padding.small
              IText { text: modelData.name; font.weight: Font.Medium }
              ITextInput { label: "Directory"; text: WallpaperService.getMonitorDirectory(modelData.name); onEditingFinished: WallpaperService.setMonitorDirectory(modelData.name, text) }
              ITextInput { label: "Wallpaper"; text: WallpaperService.getWallpaper(modelData.name); onEditingFinished: WallpaperService.changeWallpaper(text, modelData.name) }
            }
          }
        }
      }
    }
  }
}
