pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets
import "../data/keybinds.js" as Keybinds

ColumnLayout {
  id: root

  readonly property int padding: Config.appearance.padding.normal
  spacing: Config.appearance.spacing.larger

  readonly property var keybinds: Keybinds.keybinds

  ILabel {
    label: "Keybinds"
    description: "Take full control of Ling Shell with keyboard shortcuts and IPC commands. This tab covers how to start the shell and all available commands you can bind to your favorite keys."
    labelSize: Config.appearance.font.size.large
    descriptionSize: Config.appearance.font.size.smaller
  }

  IBox {
    Layout.fillWidth: true
    Layout.preferredHeight: installationCommandsRow.implicitHeight + root.padding * 2

    Row {
      id: installationCommandsRow
      anchors.fill: parent
      anchors.margins: root.padding

      spacing: Config.appearance.spacing.small

      IIcon {
        Layout.alignment: Qt.AlignTop
        icon: "rocket_launch"
        pointSize: Config.appearance.font.size.large
      }

      Column {
        Layout.alignment: Qt.AlignTop
        spacing: Config.appearance.spacing.small

        IText {
          text: "Installation-specific commands"
          pointSize: Config.appearance.font.size.larger
        }

        IText {
          text: "• NixOS Flake users: Use ling-shell directly instead of qs -c ling-shell"
        }

        IText {
          text: "• Manual installation users: If you have Ling Shell in ~/.config/quickshell/, you can use qs ipc call... directly"
        }
      }
    }
  }

  Repeater {
    id: repeater

    model: root.keybinds

    delegate: ColumnLayout {
      id: keybindItem

      required property var modelData

      spacing: Config.appearance.spacing.normal

      ILabel {
        label: keybindItem.modelData.title
      }

      RowLayout {
        spacing: Config.appearance.spacing.small

        IText {
          Layout.preferredWidth: 200
          text: "Function"
        }
        IText {
          Layout.fillWidth: true
          text: "Command"
        }
        IText {
          Layout.preferredWidth: 360
          text: "Description"
        }
      }

      Repeater {
        id: keybindActions

        model: keybindItem.modelData.actions

        delegate: RowLayout {
          id: keybindActionItem

          required property var modelData
          spacing: Config.appearance.spacing.normal

          IText {
            Layout.preferredWidth: 200
            Layout.alignment: Qt.AlignTop
            text: keybindActionItem.modelData.fn
            wrapMode: Text.WordWrap
          }

          Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: commandBox.implicitHeight

            IBox {
              id: commandBox
              implicitHeight: commandText.implicitHeight
              implicitWidth: Math.min(commandText.implicitWidth, parent.width)

              IText {
                id: commandText
                width: parent.width
                wrapMode: Text.WordWrap
                padding: Config.appearance.padding.smaller
                text: keybindActionItem.modelData.command
                family: Config.appearance.font.family.mono
              }
            }
          }

          IText {
            Layout.preferredWidth: 360
            Layout.alignment: Qt.AlignTop
            text: keybindActionItem.modelData.description
            wrapMode: Text.WordWrap
          }
        }
      }

      IDivider {
        Layout.fillWidth: true
        Layout.topMargin: root.padding
        Layout.bottomMargin: root.padding
      }
    }
  }
}
