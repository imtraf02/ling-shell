import Quickshell
import QtQuick
import qs.commons
import qs.services
import qs.modules.panels.calendar as Calendar
import qs.modules.panels.battery as Battery
import qs.modules.panels.audio as Audio
import qs.modules.panels.wifi as Wifi
import qs.modules.panels.brightness as Brightness
import qs.modules.panels.launcher as Launcher
import qs.modules.panels.tray as Tray
import qs.modules.panels.controlcenter as ControlCenter
import qs.modules.panels.bluetooth as Bluetooth
import qs.modules.panels.media as Media
import qs.modules.panels.session as Session
import qs.modules.panels.settings as SettingsPanel
import qs.modules.panels.notifications as NotificationsPanel
import qs.modules.notifications as NotificationsPopout

Item {
  id: root

  required property ShellScreen screen
  required property Item bar

  readonly property alias calendar: calendar
  readonly property alias battery: battery
  readonly property alias audio: audio
  readonly property alias wifi: wifi
  readonly property alias brightness: brightness
  readonly property alias launcher: launcher
  readonly property alias trayDrawer: trayDrawer
  readonly property alias trayMenu: trayMenu
  readonly property alias controlCenter: controlCenter
  readonly property alias bluetooth: bluetooth
  readonly property alias media: media
  readonly property alias session: session
  readonly property alias notificationsPanel: notificationsPanel
  readonly property alias notificationsPopout: notificationsPopout
  readonly property alias settings: settings

  anchors.fill: parent
  anchors.margins: Settings.appearance.thickness
  anchors.topMargin: bar.implicitHeight

  function initPanel(panel, name) {
    panel.objectName = name + "-" + (screen?.name || "unknown");
    VisibilityService.registerPanel(panel);
  }

  Calendar.Panel {
    id: calendar
    screen: root.screen
    bar: root.bar
    Component.onCompleted: root.initPanel(calendar, "calendar")
  }

  Battery.Panel {
    id: battery
    screen: root.screen
    bar: root.bar
    Component.onCompleted: root.initPanel(battery, "battery")
  }

  Audio.Panel {
    id: audio
    screen: root.screen
    bar: root.bar
    Component.onCompleted: root.initPanel(audio, "audio")
  }

  Wifi.Panel {
    id: wifi
    screen: root.screen
    bar: root.bar
    Component.onCompleted: root.initPanel(wifi, "wifi")
  }

  Brightness.Panel {
    id: brightness
    screen: root.screen
    bar: root.bar
    Component.onCompleted: root.initPanel(brightness, "brightness")
  }

  Tray.DrawerPanel {
    id: trayDrawer
    screen: root.screen
    bar: root.bar
    Component.onCompleted: root.initPanel(trayDrawer, "tray-drawer")
  }

  Tray.MenuPanel {
    id: trayMenu
    screen: root.screen
    bar: root.bar
    Component.onCompleted: root.initPanel(trayMenu, "tray-menu")
  }

  ControlCenter.Panel {
    id: controlCenter
    screen: root.screen
    bar: root.bar
    Component.onCompleted: root.initPanel(controlCenter, "control-center")
  }

  Media.Panel {
    id: media
    screen: root.screen
    bar: root.bar
    Component.onCompleted: root.initPanel(media, "media")
  }

  Bluetooth.Panel {
    id: bluetooth
    screen: root.screen
    bar: root.bar
    Component.onCompleted: root.initPanel(bluetooth, "bluetooth")
  }

  NotificationsPanel.Panel {
    id: notificationsPanel
    screen: root.screen
    bar: root.bar
    Component.onCompleted: root.initPanel(notificationsPanel, "notifications")
  }

  NotificationsPopout.Panel {
    id: notificationsPopout
    panel: root.notificationsPanel

    anchors.bottom: parent.bottom
    anchors.right: parent.right
  }

  Launcher.Panel {
    id: launcher
    screen: root.screen
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    Component.onCompleted: root.initPanel(launcher, "launcher")
  }

  Session.Panel {
    id: session
    screen: root.screen
    anchors.verticalCenter: parent.verticalCenter
    anchors.right: parent.right
    Component.onCompleted: root.initPanel(session, "session")
  }

  SettingsPanel.Panel {
    id: settings
    screen: root.screen
    anchors.centerIn: parent
    Component.onCompleted: root.initPanel(settings, "settings")
  }
}
