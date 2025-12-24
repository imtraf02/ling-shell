pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.config
import qs.commons
import qs.widgets
import qs.services
import qs.utils
import ".."

ColumnLayout {
  id: root

  property var panel

  readonly property int padding: Config.appearance.padding.normal
  spacing: Config.appearance.spacing.larger

  RowLayout {
    spacing: root.spacing
    ColumnLayout {
      spacing: root.spacing
      Layout.alignment: Qt.AlignTop

      ILabel {
        label: "System"
        description: "Overview of your current system."
        labelSize: Config.appearance.font.size.large
        descriptionSize: Config.appearance.font.size.smaller
      }

      RowLayout {
        spacing: root.spacing

        IColouredIcon {
          id: iconImage
          source: DistroService.osLogo
          implicitSize: 88
          asynchronous: true
          colour: ThemeService.palette.mPrimary
          Layout.alignment: Qt.AlignTop | Qt.AlignLeft
        }

        ColumnLayout {
          spacing: root.spacing

          IText {
            text: "OS: " + DistroService.osPretty
            family: Settings.appearance.font.mono
          }

          IText {
            text: "WM: " + DistroService.wm
            family: Settings.appearance.font.mono
          }

          IText {
            text: "USER: " + DistroService.user
            family: Settings.appearance.font.mono
          }

          IText {
            text: "UP: " + DistroService.uptime
            family: Settings.appearance.font.mono
          }

          IText {
            visible: UPower.displayDevice.isLaptopBattery
            family: Settings.appearance.font.mono
            text: `BATT: ${UPower.onBattery ? "" : "(+) "}${Math.round(UPower.displayDevice.percentage * 100)}%`
          }
        }
      }
    }

    ColumnLayout {
      spacing: root.spacing
      Layout.alignment: Qt.AlignTop

      ILabel {
        label: "Profile"
        description: "Edit your user details and avatar."
        labelSize: Config.appearance.font.size.large
        descriptionSize: Config.appearance.font.size.smaller
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: root.spacing

        IImageCircled {
          Layout.preferredWidth: 88
          Layout.preferredHeight: width
          imagePath: FileUtils.trimFileProtocol(Settings.general.avatarImage)
          fallbackIcon: "person"
          borderColor: ThemeService.palette.mPrimary
          borderWidth: 1
          Layout.alignment: Qt.AlignTop
        }

        ITextInputButton {
          Layout.alignment: Qt.AlignTop
          label: DistroService.user + "'s Profile picture"
          description: "Your profile picture that appears throughout the interface."
          text: Settings.general.avatarImage
          placeholderText: "/home/user/.face"
          buttonIcon: "photo"
          onInputEditingFinished: Settings.general.avatarImage = text
          onButtonClicked: {
            avatarPicker.openFilePicker();
          }
        }
      }

      IFilePicker {
        id: avatarPicker
        title: "Select avatar image"
        selectionMode: "files"
        initialPath: FileUtils.trimFileProtocol(Settings.general.avatarImage).substr(0, FileUtils.trimFileProtocol(Settings.general.avatarImage).lastIndexOf("/")) || Quickshell.env("HOME")
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.pnm", "*.bmp", "*.face"]
        onAccepted: paths => {
          if (paths.length > 0) {
            Settings.general.avatarImage = paths[0];
          }
        }
      }
    }
  }

  IDivider {
    Layout.fillWidth: true
    Layout.topMargin: root.padding
    Layout.bottomMargin: root.padding
  }

  ColumnLayout {
    spacing: Config.appearance.spacing.small

    SettingsTab {
      label: "Personalization"
      description: "Themes, colors, fonts, and visual preferences."
      icon: "palette"
      tab: Panel.Tab.Personalization
    }

    SettingsTab {
      label: "Bar"
      description: "Configure the system bar layout and behavior."
      icon: "crop_16_9"
      tab: Panel.Tab.Bar
    }

    SettingsTab {
      label: "Display"
      description: "Screen resolution, scaling, and arrangement."
      icon: "tv"
      tab: Panel.Tab.Display
    }

    SettingsTab {
      label: "Audio"
      description: "Input, output, and sound preferences."
      icon: "speaker"
      tab: Panel.Tab.Audio
    }

    SettingsTab {
      label: "Network"
      description: "Wi-Fi, Ethernet, and network connections."
      icon: "lan"
      tab: Panel.Tab.Network
    }

    SettingsTab {
      label: "About"
      description: "System information and Ling Shell version."
      icon: "info"
      tab: Panel.Tab.About
    }
  }

  IDivider {
    Layout.fillWidth: true
    Layout.topMargin: root.padding
    Layout.bottomMargin: root.padding
  }

  component SettingsTab: Rectangle {
    id: settingsTab
    required property string label
    required property string icon
    required property string description
    required property int tab

    Layout.fillWidth: true
    Layout.preferredHeight: 56

    color: ThemeService.palette.mSurface
    radius: Settings.appearance.cornerRadius

    IStateLayer {
      color: ThemeService.palette.mSurfaceContainerHigh
      function onClicked() {
        for (let i = 0; i < root.panel.tabsModel.length; i++) {
          if (root.panel.tabsModel[i].id === settingsTab.tab) {
            root.panel.currentTabIndex = i;
            break;
          }
        }
      }
    }

    RowLayout {
      anchors.fill: parent
      anchors.margins: root.padding
      spacing: Config.appearance.spacing.small

      IIcon {
        icon: settingsTab.icon
        pointSize: Config.appearance.font.size.extraLarge
      }

      ILabel {
        label: settingsTab.label
        description: settingsTab.description
      }

      IIcon {
        icon: "keyboard_arrow_right"
        pointSize: Config.appearance.font.size.large
        color: ThemeService.palette.mOutline
      }
    }
  }
}
