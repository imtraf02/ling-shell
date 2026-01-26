import Quickshell
import QtQuick
import qs.common
import qs.modules.panels.clock as Clock
import qs.modules.panels.media as Media
import qs.modules.panels.tray as Tray
import qs.modules.panels.network as Network
import qs.modules.panels.battery as Battery
import qs.modules.panels.launcher as Launcher
import qs.modules.panels.brightness as Brightness
import qs.modules.panels.audio as Audio
import qs.modules.panels.controlcenter as ControlCenter
import qs.modules.panels.session as Session
import qs.modules.panels.notifications as Notifications
import qs.modules.panels.settings as SettingsPanel
import qs.modules.notifications as NotificationsPopout

Item {
  id: root

  required property ShellScreen screen
  required property Item bar

  readonly property alias notificationsPanel: notificationsPanel
  readonly property alias notificationsPopout: notificationsPopout

  anchors.fill: parent
  anchors.margins: Settings.appearance.thickness
  anchors.topMargin: bar.implicitHeight

  Clock.Panel {
    id: clockPanel
    objectName: "panel:clock-" + (root.screen?.name || "unknown")
    screen: root.screen
  }

  Media.Panel {
    id: mediaPanel
    objectName: "panel:media-" + (root.screen?.name || "unknown")
    screen: root.screen
  }

  Tray.DrawerPanel {
    id: trayDrawerPanel
    objectName: "panel:tray-drawer-" + (root.screen?.name || "unknown")
    screen: root.screen
  }

  Tray.MenuPanel {
    id: trayMenuPanel
    objectName: "panel:tray-menu-" + (root.screen?.name || "unknown")
    screen: root.screen
  }

  Network.Panel {
    id: networkPanel
    objectName: "panel:network-" + (root.screen?.name || "unknown")
    screen: root.screen
  }

  Battery.Panel {
    id: batteryPanel
    objectName: "panel:battery-" + (root.screen?.name || "unknown")
    screen: root.screen
  }

  Launcher.Panel {
    id: launcherPanel
    objectName: "panel:launcher-" + (root.screen?.name || "unknown")
    screen: root.screen
  }

  Brightness.Panel {
    id: brightnessPanel
    objectName: "panel:brightness-" + (root.screen?.name || "unknown")
    screen: root.screen
  }

  Audio.Panel {
    id: audioPanel
    objectName: "panel:audio-" + (root.screen?.name || "unknown")
    screen: root.screen
  }

  ControlCenter.Panel {
    id: controlCenterPanel
    objectName: "panel:control-center-" + (root.screen?.name || "unknown")
    screen: root.screen
  }

  Session.Panel {
    id: sessionPanel
    objectName: "panel:session-" + (root.screen?.name || "unknown")
    screen: root.screen
  }

  SettingsPanel.Panel {
    id: settingsPanel
    objectName: "panel:settings-" + (root.screen?.name || "unknown")
    screen: root.screen
  }

  Notifications.Panel {
    id: notificationsPanel
    objectName: "panel:notifications-" + (root.screen?.name || "unknown")
    screen: root.screen
  }

  NotificationsPopout.Panel {
    id: notificationsPopout

    screen: root.screen
    panel: root.notificationsPanel
    anchors.bottom: parent.bottom
    anchors.right: parent.right
  }
}
