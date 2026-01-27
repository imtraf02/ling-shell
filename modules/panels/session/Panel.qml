pragma ComponentBehavior: Bound

import QtQuick
import qs.common
import qs.widgets
import qs.services
import qs.modules.panels
import qs.utils

SmartPanel {
  id: root

  position: "right"

  panelContent: Item {
    id: panelContent
    anchors.fill: parent

    readonly property real contentPreferredWidth: col.implicitWidth
    readonly property real contentPreferredHeight: col.implicitHeight

    Column {
      id: col

      padding: Style.padding.small
      spacing: Style.spacing.small

      SessionButton {
        id: logout

        icon: "logout"
        onClicked: CompositorService.logout()
        KeyNavigation.down: shutdown

        Component.onCompleted: forceActiveFocus()
      }

      SessionButton {
        id: shutdown

        icon: "power_settings_new"
        onClicked: CompositorService.shutdown()

        KeyNavigation.up: logout
        KeyNavigation.down: hibernate
      }

      AnimatedImage {
        width: Style.widget.size * 3
        height: Style.widget.size * 3
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
        onClicked: CompositorService.suspend()

        KeyNavigation.up: shutdown
        KeyNavigation.down: reboot
      }

      SessionButton {
        id: reboot

        icon: "cached"
        onClicked: CompositorService.reboot()

        KeyNavigation.up: hibernate
      }
    }
  }

  component SessionButton: Rectangle {
    id: button

    required property string icon

    implicitWidth: Style.widget.size * 3
    implicitHeight: Style.widget.size * 3

    radius: Style.rounding.small
    color: button.activeFocus ? ThemeService.palette.mPrimaryContainer : ThemeService.palette.mSurfaceContainer

    signal clicked

    Keys.onEnterPressed: clicked()
    Keys.onReturnPressed: clicked()
    Keys.onEscapePressed: root.close()
    Keys.onPressed: event => {
      if (!Settings.session.vimKeybinds)
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
      color: button.activeFocus ? ThemeService.palette.mPrimaryContainer : ThemeService.palette.mSurfaceContainer

      function onClicked(): void {
        button.clicked();
      }
    }

    IIcon {
      anchors.centerIn: parent

      icon: button.icon
      color: button.activeFocus ? ThemeService.palette.mOnPrimaryContainer : ThemeService.palette.mOnSurface
      font.pointSize: Style.font.size.extraLarge
    }
  }
}
