pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons
import "../../../../helpers/fuzzysort.js" as Fuzzysort

Singleton {
  id: root

  readonly property string usageFilePath: Directories.shellCacheLauncherAppUsagePath

  readonly property list<DesktopEntry> list: typeof DesktopEntries === 'undefined' ? [] : DesktopEntries.applications.values.filter(app => app && !app.noDisplay).map(app => {
    app.executableName = getExecutableName(app);
    return app;
  })

  Timer {
    id: saveTimer
    interval: 750
    repeat: false
    onTriggered: usageFile.writeAdapter()
  }

  FileView {
    id: usageFile
    path: usageFilePath
    printErrors: false
    watchChanges: false

    onLoadFailed: function (error) {
      if (error === FileViewError.FileNotFound) {
        writeAdapter();
      }
    }

    onAdapterUpdated: saveTimer.start()

    JsonAdapter {
      id: usageAdapter
      property var counts: ({})
    }
  }

  function getExecutableName(app) {
    if (!app)
      return "";

    if (app.command && Array.isArray(app.command) && app.command.length > 0) {
      const cmd = app.command[0];
      const parts = cmd.split('/');
      const executable = parts[parts.length - 1];
      return executable.split(' ')[0];
    }

    if (app.exec) {
      const parts = app.exec.split('/');
      const executable = parts[parts.length - 1];
      return executable.split(' ')[0];
    }

    if (app.id) {
      return app.id.replace('.desktop', '');
    }

    return "";
  }

  function search(q: string): list<var> {
    if (!q || q.length === 0) {
      return [...list].sort((a, b) => {
        const ua = usageAdapter.counts[a.id] || 0;
        const ub = usageAdapter.counts[b.id] || 0;
        return ub - ua;
      });
    }

    const results = Fuzzysort.go(q, list, {
      all: true,
      keys: ["name", "comment", "genericName", "executableName"],
      "threshold": -1000
    });

    const items = results.map(r => r.obj);

    return items.sort((a, b) => {
      const ua = usageAdapter.counts[a.id] || 0;
      const ub = usageAdapter.counts[b.id] || 0;
      if (ua !== ub)
        return ub - ua;

      const sa = results.find(r => r.obj === a)?.score || 0;
      const sb = results.find(r => r.obj === b)?.score || 0;
      return sb - sa;
    });
  }

  function launch(entry: DesktopEntry): void {
    usageAdapter.counts[entry.id] = (usageAdapter.counts[entry.id] || 0) + 1;
    saveTimer.restart();

    let cmd = [];

    if (ProgramCheckerService.app2unitAvailable) {
      if (entry.runInTerminal)
        cmd = ["app2unit", "--", "ghostty", "-e", ...entry.command];
      else
        cmd = ["app2unit", "--", ...entry.command];
    } else {
      if (entry.runInTerminal)
        cmd = ["ghostty", "-e", ...entry.command];
      else
        cmd = [...entry.command];
    }

    Quickshell.execDetached({
      command: cmd,
      workingDirectory: entry.workingDirectory
    });
  }
}
