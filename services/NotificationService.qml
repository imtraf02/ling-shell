pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import qs.config
import qs.commons
import qs.widgets
import qs.services

Singleton {
  id: root

  property list<Notif> list: []
  readonly property list<Notif> notClosed: list.filter(n => !n.closed)
  readonly property list<Notif> popups: list.filter(n => n.popup)
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
    }
  }

  FileView {
    id: storage
    path: Directories.shellStateNotificationsPath

    onLoaded: {
      const data = JSON.parse(text());
      for (const n of data)
        root.list.push(notifComp.createObject(root, n));
      root.list.sort((a, b) => b.time - a.time);
      root.loaded = true;
    }

    onLoadFailed: err => {
      if (err === FileViewError.FileNotFound) {
        root.loaded = true;
        setText("[]");
      }
    }
  }

  function clear() {
    try {
      Quickshell.execDetached(["sh", "-c", `rm -rf "
${Directories.shellCacheNotificationsDir}"*`]);
    } catch (e) {
      console.error("Notifications", "Failed to clear cache directory:", e);
    }
    root.list = [];
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
        return qsTr("now");
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
    property real expireTimeout: Config.notifications.defaultExpireTimeout
    property int urgency: NotificationUrgency.Normal
    property bool resident
    property bool hasActionIcons
    property list<var> actions

    readonly property Timer timer: Timer {
      running: true
      interval: notif.expireTimeout > 0 ? notif.expireTimeout : Config.notifications.defaultExpireTimeout
      onTriggered: {
        if (Config.notifications.expire)
          notif.popup = false;
      }
    }

    readonly property LazyLoader dummyImageLoader: LazyLoader {
      active: false
      PanelWindow {
        implicitWidth: Config.notifications.sizes.image
        implicitHeight: Config.notifications.sizes.image
        color: "transparent"
        mask: Region {}
        IImageCached {
          anchors.fill: parent
          fillMode: Image.PreserveAspectCrop
          cache: false
          asynchronous: true
          opacity: 0
          maxCacheDimension: 384
          imagePath: Qt.resolvedUrl(notif.image)
          cacheFolder: Directories.shellCacheNotificationsDir
        }
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
        if (notif.notification?.image)
          notif.dummyImageLoader.active = true;
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
      if (notification.image)
        dummyImageLoader.active = true;
    }
  }

  Component {
    id: notifComp
    Notif {}
  }
}
