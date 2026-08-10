pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import qs.common
import qs.services

Singleton {
  id: root

  property var list: []
  readonly property var notClosed: (list || []).filter(n => n && !n.closed)
  readonly property var popups: (list || []).filter(n => n && n.popup && !n.closed)
  property alias dnd: props.dnd

  property bool loaded

  onDndChanged: {}

  onListChanged: {
    if (loaded)
      saveTimer.restart();
  }

  Timer {
    id: saveTimer
    interval: 1000

    onTriggered: storage.setText(JSON.stringify(root.notClosed.map(n => ({
          time: n.time,
          id: n.id,
          summary: n.summary,
          body: n.body,
          appIcon: n.appIcon,
          appName: n.appName,
          image: n.image,
          expireTimeout: n.expireTimeout,
          urgency: n.urgency,
          resident: n.resident,
          hasActionIcons: n.hasActionIcons,
          actions: n.actions
        }))))
  }

  PersistentProperties {
    id: props
    property bool dnd
    reloadableId: "notifs"
  }

  NotificationServer {
    id: server

    keepOnReload: false
    actionsSupported: true
    bodyHyperlinksSupported: true
    bodyImagesSupported: true
    bodyMarkupSupported: true
    imageSupported: true
    persistenceSupported: true

    onNotification: notif => {
      notif.tracked = true;
      const comp = notifComp.createObject(root, {
        popup: !props.dnd,
        notification: notif
      });
      root.list = [comp, ...root.list];
      root.pruneHistory();
    }
  }

  FileView {
    id: storage
    path: Directories.shellConfigNotificationsPath

    onLoaded: {
      try {
        const data = JSON.parse(text());
        const cutoff = root.retentionCutoff();
        const limit = Math.max(10, Settings.notifications.historyLimit);
        const valid = data.filter(n => n && new Date(n.time).getTime() >= cutoff).sort((a, b) => new Date(b.time).getTime() - new Date(a.time).getTime()).slice(0, limit);
        root.list = valid.map(n => notifComp.createObject(root, n)).filter(Boolean);
      } catch (e) {
        root.list = [];
      }
      root.loaded = true;
      root.pruneHistory();
    }

    onLoadFailed: err => {
      if (err === FileViewError.FileNotFound) {
        root.loaded = true;
        setText("[]");
      }
    }
  }

  Connections {
    target: Settings.notifications
    function onHistoryLimitChanged() { root.pruneHistory(); }
    function onHistoryRetentionDaysChanged() { root.pruneHistory(); }
  }

  function retentionCutoff() {
    const days = Math.max(1, Settings.notifications.historyRetentionDays);
    return Date.now() - days * 24 * 60 * 60 * 1000;
  }

  function destroyNotification(notif) {
    if (!notif)
      return;
    notif.closed = true;
    notif.notification?.dismiss();
    notif.destroy();
  }

  function pruneHistory() {
    const cutoff = retentionCutoff();
    const limit = Math.max(10, Settings.notifications.historyLimit);
    const valid = (root.list || []).filter(n => n && !n.closed && n.time.getTime() >= cutoff).sort((a, b) => b.time.getTime() - a.time.getTime());
    const keep = valid.slice(0, limit);
    const removed = (root.list || []).filter(n => n && !keep.includes(n));
    if (removed.length === 0 && keep.length === root.list.length)
      return;
    root.list = keep;
    for (const notif of removed)
      destroyNotification(notif);
  }

  function clear() {
    const oldList = (root.list || []).slice();
    root.list = [];
    for (const notif of oldList)
      root.destroyNotification(notif);
    try {
      Quickshell.execDetached(["find", Directories.shellCacheNotificationsDir, "-maxdepth", "1", "-type", "f", "-delete"]);
    } catch (e) {
      console.error("Notifications", "Failed to clear cache directory:", e);
    }
  }

  component Notif: QtObject {
    id: notif

    property bool popup
    property bool closed
    property var locks: new Set()
    property date time: new Date()

    readonly property string timeStr: {
      const diff = TimeService.date.getTime() - time.getTime();
      const m = Math.floor(diff / 60000);
      if (m < 1)
        return "now";
      const h = Math.floor(m / 60);
      const d = Math.floor(h / 24);
      if (d > 0)
        return `${d}d`;
      if (h > 0)
        return `${h}h`;
      return `${m}m`;
    }

    property Notification notification
    property string id
    property string summary
    property string body
    property string appIcon
    property string appName
    property string image
    property real expireTimeout: Settings.notifications.defaultExpireTimeout
    property int urgency: NotificationUrgency.Normal
    property bool resident
    property bool hasActionIcons
    property list<var> actions

    readonly property Timer timer: Timer {
      running: notif.popup && Settings.notifications.expire
      interval: notif.expireTimeout > 0 ? notif.expireTimeout : Settings.notifications.defaultExpireTimeout
      onTriggered: {
        if (Settings.notifications.expire)
          notif.popup = false;
      }
    }

    readonly property Connections conn: Connections {
      target: notif.notification

      function onClosed() {
        notif.close();
      }
      function onSummaryChanged() {
        notif.summary = notif.notification.summary;
      }
      function onBodyChanged() {
        notif.body = notif.notification.body;
      }
      function onAppIconChanged() {
        notif.appIcon = notif.notification.appIcon;
      }
      function onAppNameChanged() {
        notif.appName = notif.notification.appName;
      }
      function onImageChanged() {
        notif.image = notif.notification.image;
      }
      function onExpireTimeoutChanged() {
        notif.expireTimeout = notif.notification.expireTimeout;
      }
      function onUrgencyChanged() {
        notif.urgency = notif.notification.urgency;
      }
      function onResidentChanged() {
        notif.resident = notif.notification.resident;
      }
      function onHasActionIconsChanged() {
        notif.hasActionIcons = notif.notification.hasActionIcons;
      }
      function onActionsChanged() {
        notif.actions = notif.notification.actions.map(a => ({
              identifier: a.identifier,
              text: a.text,
              invoke: () => a.invoke()
            }));
      }
    }

    function lock(item) {
      locks.add(item);
    }

    function unlock(item) {
      locks.delete(item);
      if (closed)
        close();
    }

    function close() {
      closed = true;
      if (locks.size === 0 && root.list.includes(this)) {
        root.list = root.list.filter(n => n !== this);
        notification?.dismiss();
        destroy();
      }
    }

    Component.onCompleted: {
      if (!notification)
        return;
      id = notification.id;
      summary = notification.summary;
      body = notification.body;
      appIcon = notification.appName === "niri" ? "" : notification.appIcon;
      appName = notification.appName;
      image = notification.image;
      expireTimeout = notification.expireTimeout;
      urgency = notification.urgency;
      resident = notification.resident;
      hasActionIcons = notification.hasActionIcons;
      actions = notification.actions.map(a => ({
            identifier: a.identifier,
            text: a.text,
            invoke: () => a.invoke()
          }));
    }
  }

  Component {
    id: notifComp
    Notif {}
  }
}
