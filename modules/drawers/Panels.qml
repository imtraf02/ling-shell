pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.common
import qs.services
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
import qs.modules.panels.bluetooth as Bluetooth
import qs.modules.panels.dashboard as Dashboard
import qs.modules.notifications as NotificationsPopout

Item {
  id: root

  required property ShellScreen screen
  required property Item bar

  readonly property var notificationsPanel: notificationsPanelLoader.item
  readonly property alias notificationsPopout: notificationsPopout
  property var pendingReleases: ({})

  anchors.fill: parent
  anchors.margins: Settings.appearance.thickness
  anchors.topMargin: bar.implicitHeight

  Component.onCompleted: PanelService.registerPanelHost(root.screen, root)
  Component.onDestruction: PanelService.unregisterPanelHost(root.screen, root)

  function loaderForPanel(name) {
    switch (name) {
    case "panel:clock": return clockPanelLoader;
    case "panel:media": return mediaPanelLoader;
    case "panel:tray-drawer": return trayDrawerPanelLoader;
    case "panel:tray-menu": return trayMenuPanelLoader;
    case "panel:network": return networkPanelLoader;
    case "panel:battery": return batteryPanelLoader;
    case "panel:launcher": return launcherPanelLoader;
    case "panel:brightness": return brightnessPanelLoader;
    case "panel:audio": return audioPanelLoader;
    case "panel:control-center": return controlCenterPanelLoader;
    case "panel:session": return sessionPanelLoader;
    case "panel:settings": return settingsPanelLoader;
    case "panel:notifications": return notificationsPanelLoader;
    case "panel:bluetooth": return bluetoothPanelLoader;
    case "panel:dashboard": return dashboardPanelLoader;
    }
    return null;
  }

  function observePanel(name, panel) {
    if (!panel)
      return;
    panel.closed.connect(() => root.scheduleRelease(name, panel));
  }

  function scheduleRelease(name, panel) {
    const next = Object.assign({}, pendingReleases);
    next[name] = { panel: panel, deadline: Date.now() + 10000 };
    pendingReleases = next;
    releaseTimer.start();
  }

  function cancelRelease(name) {
    if (!pendingReleases[name])
      return;
    const next = Object.assign({}, pendingReleases);
    delete next[name];
    pendingReleases = next;
  }

  function releaseExpiredPanels() {
    const now = Date.now();
    const next = Object.assign({}, pendingReleases);
    for (const name in pendingReleases) {
      const entry = pendingReleases[name];
      const loader = loaderForPanel(name);
      if (!entry || !loader || loader.item !== entry.panel) {
        delete next[name];
        continue;
      }
      if (entry.deadline > now)
        continue;
      if (!entry.panel.isPanelOpen && !entry.panel.isPanelVisible && !entry.panel.isClosing) {
        PanelService.unregisterPanel(entry.panel);
        loader.active = false;
        delete next[name];
      }
    }
    pendingReleases = next;
    if (Object.keys(next).length === 0)
      releaseTimer.stop();
  }

  function ensurePanel(name) {
    const loader = loaderForPanel(name);
    if (!loader)
      return null;
    cancelRelease(name);
    loader.active = true;
    return loader.item;
  }

  Timer {
    id: releaseTimer
    interval: 1000
    repeat: true
    onTriggered: root.releaseExpiredPanels()
  }

  component LazyPanelLoader: Loader {
    required property string panelName
    anchors.fill: parent
    active: false
    onLoaded: root.observePanel(panelName, item)
  }

  Component { id: clockPanelComponent; Clock.Panel { objectName: "panel:clock-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: mediaPanelComponent; Media.Panel { objectName: "panel:media-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: trayDrawerPanelComponent; Tray.DrawerPanel { objectName: "panel:tray-drawer-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: trayMenuPanelComponent; Tray.MenuPanel { objectName: "panel:tray-menu-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: networkPanelComponent; Network.Panel { objectName: "panel:network-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: batteryPanelComponent; Battery.Panel { objectName: "panel:battery-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: launcherPanelComponent; Launcher.Panel { objectName: "panel:launcher-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: brightnessPanelComponent; Brightness.Panel { objectName: "panel:brightness-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: audioPanelComponent; Audio.Panel { objectName: "panel:audio-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: controlCenterPanelComponent; ControlCenter.Panel { objectName: "panel:control-center-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: sessionPanelComponent; Session.Panel { objectName: "panel:session-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: settingsPanelComponent; SettingsPanel.Panel { objectName: "panel:settings-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: notificationsPanelComponent; Notifications.Panel { objectName: "panel:notifications-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: bluetoothPanelComponent; Bluetooth.Panel { objectName: "panel:bluetooth-" + (root.screen?.name || "unknown"); screen: root.screen } }
  Component { id: dashboardPanelComponent; Dashboard.Panel { objectName: "panel:dashboard-" + (root.screen?.name || "unknown"); screen: root.screen } }

  LazyPanelLoader { id: clockPanelLoader; panelName: "panel:clock"; sourceComponent: clockPanelComponent }
  LazyPanelLoader { id: mediaPanelLoader; panelName: "panel:media"; sourceComponent: mediaPanelComponent }
  LazyPanelLoader { id: trayDrawerPanelLoader; panelName: "panel:tray-drawer"; sourceComponent: trayDrawerPanelComponent }
  LazyPanelLoader { id: trayMenuPanelLoader; panelName: "panel:tray-menu"; sourceComponent: trayMenuPanelComponent }
  LazyPanelLoader { id: networkPanelLoader; panelName: "panel:network"; sourceComponent: networkPanelComponent }
  LazyPanelLoader { id: batteryPanelLoader; panelName: "panel:battery"; sourceComponent: batteryPanelComponent }
  LazyPanelLoader { id: launcherPanelLoader; panelName: "panel:launcher"; sourceComponent: launcherPanelComponent }
  LazyPanelLoader { id: brightnessPanelLoader; panelName: "panel:brightness"; sourceComponent: brightnessPanelComponent }
  LazyPanelLoader { id: audioPanelLoader; panelName: "panel:audio"; sourceComponent: audioPanelComponent }
  LazyPanelLoader { id: controlCenterPanelLoader; panelName: "panel:control-center"; sourceComponent: controlCenterPanelComponent }
  LazyPanelLoader { id: sessionPanelLoader; panelName: "panel:session"; sourceComponent: sessionPanelComponent }
  LazyPanelLoader { id: settingsPanelLoader; panelName: "panel:settings"; sourceComponent: settingsPanelComponent }
  LazyPanelLoader { id: notificationsPanelLoader; panelName: "panel:notifications"; sourceComponent: notificationsPanelComponent }
  LazyPanelLoader { id: bluetoothPanelLoader; panelName: "panel:bluetooth"; sourceComponent: bluetoothPanelComponent }
  LazyPanelLoader { id: dashboardPanelLoader; panelName: "panel:dashboard"; sourceComponent: dashboardPanelComponent }

  NotificationsPopout.Panel {
    id: notificationsPopout

    screen: root.screen
    panel: root.notificationsPanel
    anchors.bottom: parent.bottom
    anchors.right: parent.right
  }
}
