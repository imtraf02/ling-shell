import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

ColumnLayout {
  spacing: Style.spacing.normal
  Component.onCompleted: ProgramCheckerService.ensure("cavaAvailable")
  SettingsPage {
    title: "Audio & Media"
    description: "Volume behavior, player selection, and optional spectrum visuals."
    icon: "volume_up"
    sectionId: "audio"
    SettingsCardGrid {
      id: grid
      SettingsCard {
        title: "Volume preview"
        description: "Configured volume behavior."
        icon: "graphic_eq"
        Layout.columnSpan: grid.columns
        IBox {
          Layout.fillWidth: true; implicitHeight: 62; color: ThemeService.palette.mSurfaceVariant
          RowLayout {
            anchors.fill: parent; anchors.margins: Style.padding.normal
            IIcon { icon: Settings.audio.volumeOverdrive ? "volume_up" : "volume_down"; color: ThemeService.palette.mPrimary }
            IText { Layout.fillWidth: true; text: Settings.audio.volumeStep + "% step" + (Settings.audio.volumeOverdrive ? " · overdrive enabled" : ""); font.weight: Font.Medium }
          }
        }
      }
      SettingsCard {
        title: "Volume & players"
        description: "Everyday media controls."
        icon: "music_note"
        SettingsSpinRow { label: "Volume step"; value: Settings.audio.volumeStep; from: 1; to: 25; suffix: "%"; onChanged: value => Settings.audio.volumeStep = value }
        IToggle { label: "Allow volume overdrive"; checked: Settings.audio.volumeOverdrive; onToggled: checked => Settings.audio.volumeOverdrive = checked }
        ITextInput { label: "Preferred player"; text: Settings.audio.preferredPlayer; onEditingFinished: Settings.audio.preferredPlayer = text }
      }
      SettingsCard {
        title: "Visualizer"
        description: "Optional Cava spectrum configuration."
        icon: "equalizer"
        badge: ProgramCheckerService.isChecked("cavaAvailable") ? (ProgramCheckerService.cavaAvailable ? "Ready" : "Unavailable") : "Checking"
        SettingsNotice { visible: ProgramCheckerService.isChecked("cavaAvailable") && !ProgramCheckerService.cavaAvailable; warning: true; icon: "extension_off"; text: "Cava is bundled by default. Rebuild the package if it is unavailable." }
        SettingsSpinRow { label: "Frame rate"; value: Settings.audio.cavaFrameRate; from: 10; to: 120; suffix: " fps"; onChanged: value => Settings.audio.cavaFrameRate = value }
        SettingsChoiceGroup { label: "Visualizer type"; currentKey: Settings.audio.visualizerType; model: [{ key: "linear", name: "Linear", icon: "equalizer" }, { key: "waves", name: "Waves", icon: "waves" }]; onSelected: key => Settings.audio.visualizerType = key }
      }
      SettingsCard {
        title: "Ignored players"
        description: "MPRIS player IDs excluded from media widgets."
        icon: "block"
        badge: String((Settings.audio.mprisBlacklist || []).length)
        Layout.columnSpan: grid.columns
        SettingsListEditor { placeholder: "playerctld"; values: Settings.audio.mprisBlacklist; onUpdated: values => Settings.audio.mprisBlacklist = values }
      }
    }
  }
}
