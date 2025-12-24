pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import qs.commons

Singleton {
  id: root
  property string filePath: Directories.shellConfigPath

  property alias appearance: adapter.appearance
  property alias bar: adapter.bar
  property alias delay: adapter.delay
  property alias launcher: adapter.launcher
  property alias session: adapter.session
  property alias lock: adapter.lock
  property alias notifications: adapter.notifications
  property alias settings: adapter.settings

  ElapsedTimer {
    id: timer
  }

  FileView {
    path: root.filePath
    watchChanges: true
    onFileChanged: {
      timer.restart();
      reload();
    }
    onLoaded: {
      try {
        JSON.parse(text());
      } catch (e) {}
    }
    onLoadFailed: error => {
      if (error == FileViewError.FileNotFound) {
        // TODO
      }
    }
    onSaveFailed: err => {}

    JsonAdapter {
      id: adapter

      property AppearanceConfig appearance: AppearanceConfig {}
      property BarConfig bar: BarConfig {}
      property DelayConfig delay: DelayConfig {}
      property LauncherConfig launcher: LauncherConfig {}
      property SessionConfig session: SessionConfig {}
      property LockConfig lock: LockConfig {}
      property NotificationsConfig notifications: NotificationsConfig {}
      property SettingsConfig settings: SettingsConfig {}
    }
  }
}
