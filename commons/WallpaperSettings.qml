import QtQuick
import Quickshell.Io
import qs.commons

JsonObject {
  property bool enabled: true
  property bool overviewEnabled: true
  property string directory: Directories.defaultWallpaperDir
  property bool enableMultiMonitorDirectories: false
  property bool recursiveSearch: false
  property bool setWallpaperOnAllMonitors: true
  property string defaultWallpaper: Directories.assetsPath + "/wallpapers/violet.jpg"
  property string fillMode: "crop"
  property color fillColor: "#000000"
  property list<var> monitors: []
  property int transitionDuration: 500
  property real transitionEdgeSmoothness: 0.05
}
