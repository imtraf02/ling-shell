pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.common
import qs.widgets
import qs.services
import qs.utils

ColumnLayout {
  id: root

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
      label: DistroService.user + "'s profile picture"
      description: "Your profile picture that appears throughout the interface."
      text: Settings.general.avatarImage
      placeholderText: "/home/user/.face"
      buttonIcon: "photo"
      onInputEditingFinished: Settings.general.avatarImage = text
      onButtonClicked: {
        avatarPicker.openFilePicker();
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
