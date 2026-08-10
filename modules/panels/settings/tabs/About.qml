import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets

ColumnLayout {
  spacing: Style.spacing.normal
  SettingsPage {
    title: "About"
    description: "Ling Shell runtime information and optional integration status."
    icon: "info"
    resetEnabled: false
    SettingsCardGrid {
      id: grid
      SettingsCard {
        title: "Ling Shell"
        description: "Niri-only QuickShell desktop shell."
        icon: "terminal"
        ITextInput { label: "Runtime configuration"; text: Directories.shellConfigSettingsPath; readOnly: true }
        ITextInput { label: "Shell directory"; text: Quickshell.shellDir; readOnly: true }
        SettingsNotice { text: "Settings save immediately to runtime JSON. A Home Manager rebuild can replace them with programs.ling-shell.settings." }
      }
      SettingsCard {
        title: "Optional integrations"
        description: "Bundled and optional runtime executables."
        icon: "extension"
        Component.onCompleted: { ProgramCheckerService.ensure("matugenAvailable"); ProgramCheckerService.ensure("ddcutilAvailable"); ProgramCheckerService.ensure("cavaAvailable"); ProgramCheckerService.ensure("nmcliAvailable"); ProgramCheckerService.ensure("mpvpaperAvailable"); ProgramCheckerService.ensure("mpvAvailable"); }
        Repeater {
          model: [{ name: "Matugen", property: "matugenAvailable" }, { name: "ddcutil", property: "ddcutilAvailable" }, { name: "Cava", property: "cavaAvailable" }, { name: "nmcli", property: "nmcliAvailable" }, { name: "mpvpaper", property: "mpvpaperAvailable" }, { name: "mpv", property: "mpvAvailable" }]
          delegate: IBox {
            required property var modelData
            Layout.fillWidth: true; implicitHeight: 34; color: ThemeService.palette.mSurfaceVariant
            RowLayout {
              anchors.fill: parent; anchors.leftMargin: Style.padding.small; anchors.rightMargin: Style.padding.small
              IText { Layout.fillWidth: true; text: modelData.name }
              IText { text: ProgramCheckerService.isChecked(modelData.property) ? (ProgramCheckerService[modelData.property] ? "Available" : "Unavailable") : "Checking…"; color: ProgramCheckerService[modelData.property] ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurfaceVariant; font.pointSize: Style.font.size.small }
            }
          }
        }
      }
    }
  }
}
