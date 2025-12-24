pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.commons
import qs.widgets
import qs.services
import qs.utils

Column {
  id: root

  required property var panel

  padding: Config.appearance.padding.normal
  spacing: Config.appearance.spacing.small

  SessionButton {
    id: logout

    icon: "logout"
    command: Config.session.commands.logout

    KeyNavigation.down: shutdown

    Component.onCompleted: forceActiveFocus()
  }

  SessionButton {
    id: shutdown

    icon: "power_settings_new"
    command: Config.session.commands.shutdown

    KeyNavigation.up: logout
    KeyNavigation.down: hibernate
  }

  AnimatedImage {
    width: Config.session.sizes.button
    height: Config.session.sizes.button
    sourceSize.width: width
    sourceSize.height: height

    playing: visible
    asynchronous: true
    speed: 0.7
    source: FileUtils.trimFileProtocol(Settings.session.gif)
  }

  SessionButton {
    id: hibernate

    icon: "downloading"
    command: Config.session.commands.hibernate

    KeyNavigation.up: shutdown
    KeyNavigation.down: reboot
  }

  SessionButton {
    id: reboot

    icon: "cached"
    command: Config.session.commands.reboot

    KeyNavigation.up: hibernate
  }

  component SessionButton: Rectangle {
    id: button

    required property string icon
    required property list<string> command

    implicitWidth: Config.session.sizes.button
    implicitHeight: Config.session.sizes.button

    radius: Settings.appearance.cornerRadius
    color: button.activeFocus ? Qt.alpha(ThemeService.palette.mSecondary, 0.9) : ThemeService.palette.mSurfaceContainer

    Keys.onEnterPressed: Quickshell.execDetached(button.command)
    Keys.onReturnPressed: Quickshell.execDetached(button.command)
    Keys.onEscapePressed: root.panel.close()
    Keys.onPressed: event => {
      if (!Config.session.vimKeybinds)
        return;

      if (event.modifiers & Qt.ControlModifier) {
        if (event.key === Qt.Key_J && KeyNavigation.down) {
          KeyNavigation.down.focus = true;
          event.accepted = true;
        } else if (event.key === Qt.Key_K && KeyNavigation.up) {
          KeyNavigation.up.focus = true;
          event.accepted = true;
        }
      } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
        KeyNavigation.down.focus = true;
        event.accepted = true;
      } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
        if (KeyNavigation.up) {
          KeyNavigation.up.focus = true;
          event.accepted = true;
        }
      }
    }

    IStateLayer {
      radius: parent.radius
      color: button.activeFocus ? ThemeService.palette.mOnSecondary : ThemeService.palette.mOnSurface

      function onClicked(): void {
        Quickshell.execDetached(button.command);
      }
    }

    IIcon {
      anchors.centerIn: parent

      icon: button.icon
      color: button.activeFocus ? ThemeService.palette.mOnSecondary : ThemeService.palette.mOnSurface
      pointSize: Config.appearance.font.size.extraLarge
    }
  }
}
