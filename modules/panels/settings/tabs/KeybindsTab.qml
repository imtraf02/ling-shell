pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.widgets
import "../data/keybinds.js" as Keybinds

ColumnLayout {
  id: root

  readonly property int padding: Style.padding.normal
  spacing: Style.spacing.larger

  readonly property var keybinds: Keybinds.keybinds

  ILabel {
    label: "Keybinds"
    description: "Take full control of Ling Shell with keyboard shortcuts and IPC commands. This tab covers how to start the shell and all available commands you can bind to your favorite keys."
    labelSize: Style.font.size.large
    descriptionSize: Style.font.size.smaller
  }

  IBox {
    Layout.fillWidth: true
    Layout.preferredHeight: installationCommandsRow.implicitHeight + root.padding * 2

    Row {
      id: installationCommandsRow
      anchors.fill: parent
      anchors.margins: root.padding

      spacing: Style.spacing.small

      IIcon {
        Layout.alignment: Qt.AlignTop
        icon: "rocket_launch"
        font.pointSize: Style.font.size.large
      }

      Column {
        Layout.alignment: Qt.AlignTop
        spacing: Style.spacing.small

        IText {
          text: "Installation-specific commands"
          font.pointSize: Style.font.size.larger
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

      spacing: Style.spacing.normal

      ILabel {
        label: keybindItem.modelData.title
      }

      Repeater {
        id: keybindActions

        model: keybindItem.modelData.actions

        delegate: RowLayout {
          id: keybindActionItem

          required property var modelData
          spacing: Style.spacing.normal

          IText {
            Layout.preferredWidth: 200
            Layout.alignment: Qt.AlignTop
            text: keybindActionItem.modelData.fn
            padding: Style.padding.smaller
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
                padding: Style.padding.smaller
                text: keybindActionItem.modelData.command
                font.family: Settings.appearance.font.mono
              }
            }
          }

          IText {
            Layout.preferredWidth: 360
            Layout.alignment: Qt.AlignTop
            text: keybindActionItem.modelData.description
            padding: Style.padding.smaller
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
