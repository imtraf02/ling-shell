import Quickshell
import QtQuick
import qs.common
import qs.services
import qs.modules
import qs.modules.background
import qs.modules.drawers
import qs.modules.lock

ShellRoot {
  id: root

  property bool settingsLoaded: false
  property bool styleLoaded: false

  Connections {
    target: Settings ? Settings : null
    function onSettingsLoaded() {
      root.settingsLoaded = true;
    }
  }

  Connections {
    target: Style ? Style : null
    function onSettingsLoaded() {
      root.styleLoaded = true;
    }
  }

  Loader {
    active: root.settingsLoaded && root.styleLoaded && Directories.ready
    sourceComponent: Item {
      Component.onCompleted: {
        ProgramCheckerService.init();
        WallpaperService.init();
        ThemeService.init();
        DistroService.init();
        FontService.init();
      }

      Background {}
      // TODO: Implement LiveBackground.qml
      // LiveBackground {}
      Overview {}
      Drawers {}
      Lock {
        id: lock
        Component.onCompleted: {
          CompositorService.lockscreen = lock.lock;
        }
      }
      Shortcuts {}
    }
  }
}
