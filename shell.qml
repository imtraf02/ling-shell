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

  Connections {
    target: Settings ? Settings : null
    function onSettingsLoaded() {
      root.settingsLoaded = true;
    }
  }

  Loader {
    active: root.settingsLoaded && Directories.ready
    sourceComponent: Item {
      Component.onCompleted: {
        ProgramCheckerService.init();
        WallpaperService.init();
        ThemeService.init();
        DistroService.init();
        FontService.init();
      }

      Background {}
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
