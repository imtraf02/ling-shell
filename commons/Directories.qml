pragma Singleton
pragma ComponentBehavior: Bound

import Qt.labs.platform
import QtQuick
import Quickshell
import qs.utils

Singleton {
  // XDG Dirs, with "file://"
  readonly property string home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
  readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
  readonly property string state: StandardPaths.standardLocations(StandardPaths.StateLocation)[0]
  readonly property string cache: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]
  readonly property string genericCache: StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]
  readonly property string documents: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
  readonly property string downloads: StandardPaths.standardLocations(StandardPaths.DownloadLocation)[0]
  readonly property string pictures: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
  readonly property string music: StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
  readonly property string videos: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]

  // Other dirs used by the shell, without "file://"
  property string shellName: "ling"
  property string assetsPath: Quickshell.shellPath("assets")
  property string defaultAvatarPath: FileUtils.trimFileProtocol(`${Directories.home}/.face`)
  property string defaultWallpaperDir: FileUtils.trimFileProtocol(`${Directories.pictures}/Wallpapers`)
  property string shellConfig: FileUtils.trimFileProtocol(`${Directories.config}/${shellName}`)
  property string shellConfigPath: `${Directories.shellConfig}/config.json`
  property string shellState: FileUtils.trimFileProtocol(`${Directories.state}/${shellName}`)
  property string shellStateColoursPath: `${Directories.shellState}/colours.json`
  property string shellStateSettingsPath: `${Directories.shellState}/settings.json`
  property string shellStateNetworkPath: `${Directories.shellState}/network.json`
  property string shellStateNotificationsPath: `${Directories.shellState}/notifications.json`
  property string shellCache: FileUtils.trimFileProtocol(`${Directories.cache}/${shellName}`)
  property string shellCacheImagesDir: `${Directories.shellCache}/images`
  property string shellCacheWallpaperDir: `${Directories.shellCacheImagesDir}/wallpapers`
  property string shellCacheNotificationsDir: `${Directories.shellCacheImagesDir}/notifications`
  property string shellCacheThumbnailDir: `${Directories.shellCacheImagesDir}/thumbnails`
  property string shellCacheLauncherAppUsagePath: `${Directories.shellCache}/launcher_app_usage.json`
  property string shellDisplayCachePath: `${Directories.shellCache}/display.json`

  Component.onCompleted: {
    Quickshell.execDetached(["mkdir", "-p", `${shellConfig}`]);
    Quickshell.execDetached(["mkdir", "-p", `${shellState}`]);
    Quickshell.execDetached(["mkdir", "-p", `${shellCache}`]);
    Quickshell.execDetached(["mkdir", "-p", `${shellCacheImagesDir}`]);
    Quickshell.execDetached(["mkdir", "-p", `${shellCacheWallpaperDir}`]);
    Quickshell.execDetached(["mkdir", "-p", `${shellCacheNotificationsDir}`]);
    Quickshell.execDetached(["mkdir", "-p", `${shellCacheThumbnailDir}`]);
  }
}
