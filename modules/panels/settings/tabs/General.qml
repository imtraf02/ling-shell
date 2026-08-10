pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.widgets
import qs.services
import qs.utils

ColumnLayout {
  id: root
  spacing: Style.spacing.normal

  SettingsPage {
    title: "General"
    description: "Profile identity and launcher behavior."
    icon: "person"
    sectionId: "general"

    SettingsCardGrid {
      id: grid
      SettingsCard {
        title: "Profile"
        description: "How you appear across Ling Shell."
        icon: "account_circle"
        Layout.columnSpan: grid.columns

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.spacing.normal
          IImageCircled {
            Layout.preferredWidth: 76
            Layout.preferredHeight: width
            imagePath: FileUtils.trimFileProtocol(Settings.general.avatarImage)
            fallbackIcon: "person"
            borderColor: ThemeService.palette.mPrimary
            borderWidth: 2
          }
          ITextInputButton {
            Layout.fillWidth: true
            label: DistroService.user + "'s profile picture"
            description: "Choose the image used in profile surfaces."
            text: Settings.general.avatarImage
            placeholderText: "/home/user/.face"
            buttonIcon: "photo"
            onInputEditingFinished: Settings.general.avatarImage = text
            onButtonClicked: avatarPicker.openFilePicker()
          }
        }
        IFilePicker {
          id: avatarPicker
          title: "Select avatar image"
          selectionMode: "files"
          initialPath: FileUtils.trimFileProtocol(Settings.general.avatarImage).substr(0, FileUtils.trimFileProtocol(Settings.general.avatarImage).lastIndexOf("/")) || Quickshell.env("HOME")
          nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.pnm", "*.bmp", "*.face"]
          onAccepted: paths => { if (paths.length > 0) Settings.general.avatarImage = paths[0]; }
        }
      }

      SettingsCard {
        title: "Search results"
        description: "Control the amount of content shown by the launcher."
        icon: "search"
        SettingsSpinRow { label: "Maximum results"; value: Settings.launcher.maxShown; from: 1; to: 30; onChanged: value => Settings.launcher.maxShown = value }
        SettingsSpinRow { label: "Maximum wallpapers"; value: Settings.launcher.maxWallpapers; from: 1; to: 50; onChanged: value => Settings.launcher.maxWallpapers = value }
      }

      SettingsCard {
        title: "Commands"
        description: "Prefixes that change what launcher input means."
        icon: "terminal"
        ITextInput { label: "Command prefix"; text: Settings.launcher.actionPrefix; onEditingFinished: Settings.launcher.actionPrefix = text }
        ITextInput { label: "Special prefix"; text: Settings.launcher.specialPrefix; onEditingFinished: Settings.launcher.specialPrefix = text }
      }

      SettingsCard {
        title: "Hidden applications"
        description: "Keep selected desktop entries out of launcher search."
        icon: "visibility_off"
        badge: String((Settings.launcher.hiddenApps || []).length)
        Layout.columnSpan: grid.columns
        SettingsListEditor { placeholder: "org.example.App"; values: Settings.launcher.hiddenApps; onUpdated: values => Settings.launcher.hiddenApps = values }
      }
    }
  }
}
