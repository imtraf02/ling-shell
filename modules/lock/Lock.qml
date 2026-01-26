pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

Scope {
  property alias lock: lock

  WlSessionLock {
    id: lock

    signal unlock

    LockSurface {
      id: lockSurface

      lock: lock
      pam: pam
    }
  }

  Pam {
    id: pam

    lock: lock
  }
}
