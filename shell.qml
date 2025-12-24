import QtQuick
import Quickshell
import qs.commons
import qs.services
import qs.modules
import qs.modules.drawers
import qs.modules.background
import qs.modules.lock

ShellRoot {
  id: root
  Loader {
    active: Settings.ready
    sourceComponent: Item {
      Component.onCompleted: {
        ProgramCheckerService.init();
        WallpaperService.init();
        BluetoothService.init();
        ThemeService.init();
        FontService.init();
        DistroService.init();
      }
      Overview {}
      Background {}
      Drawers {}
      Lock {
        id: lock
        Component.onCompleted: {
          VisibilityService.lock = lock.lock;
        }
      }
      Shortcuts {}
    }
  }
}
