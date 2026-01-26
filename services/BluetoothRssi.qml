import QtQuick
import Quickshell.Io
import "../helpers/bluetooth-utils.js" as BluetoothUtils

QtObject {
  id: root

  property bool enabled: false
  property int intervalMs: 10000
  property var connectedDevices: []

  property var cache: ({})
  property int version: 0

  property int _index: 0
  property string _currentAddr: ""

  property Process rssiProcess: Process {
    id: proc
    running: false
    stdout: StdioCollector {
      id: out
    }
    onExited: function (exitCode, exitStatus) {
      try {
        const text = out.text || "";
        const dbm = BluetoothUtils.parseRssiOutput(text);
        if (root._currentAddr !== "" && dbm !== null) {
          const pct = BluetoothUtils.dbmToPercent(dbm);
          if (pct !== null) {
            root.cache[root._currentAddr] = pct;
            root.version++;
          }
        }
      } catch (e) {} finally {
        root._currentAddr = "";
      }
    }
  }

  property Timer rssiTimer: Timer {
    interval: root.intervalMs
    repeat: true
    running: root.enabled
    onTriggered: {
      const list = root.connectedDevices || [];
      if (!list || list.length === 0)
        return;
      if (root._index >= list.length)
        root._index = 0;
      const dev = list[root._index++];
      if (!dev)
        return;
      const addr = BluetoothUtils.macFromDevice(dev);
      if (!addr || addr.length < 7)
        return;
      if (proc.running)
        return;
      root._currentAddr = addr;
      proc.command = ["sh", "-c", `bluetoothctl info "${addr}"`];
      try {
        proc.running = true;
      } catch (e) {}
    }
  }
}
