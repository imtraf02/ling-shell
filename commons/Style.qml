pragma Singleton

import QtQuick

QtObject {
  readonly property QtObject appearance: QtObject {
    readonly property QtObject rounding: QtObject {
      readonly property int small: 12
      readonly property int normal: 17
      readonly property int large: 25
      readonly property int full: 1000
    }

    readonly property QtObject spacing: QtObject {
      readonly property int small: 11
      readonly property int smaller: 12
      readonly property int normal: 13
      readonly property int larger: 15
      readonly property int large: 18
      readonly property int extraLarge: 28
    }

    readonly property QtObject padding: QtObject {
      readonly property int small: 4
      readonly property int smaller: 6
      readonly property int normal: 8
      readonly property int larger: 10
      readonly property int large: 14
    }

    readonly property QtObject font: QtObject {
      readonly property QtObject size: QtObject {
        readonly property int small: 8
        readonly property int smaller: 9
        readonly property int normal: 10
        readonly property int larger: 12
        readonly property int large: 14
        readonly property int extraLarge: 24
      }
    }

    readonly property QtObject anim: QtObject {
      readonly property QtObject curves: QtObject {
        readonly property list<real> emphasized: [0.05, 0, 0.133333, 0.06, 0.166667, 0.4, 0.208333, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        readonly property list<real> expressiveEffects: [0.34, 0.8, 0.34, 1, 1, 1]
      }

      readonly property QtObject durations: QtObject {
        readonly property int small: 200
        readonly property int normal: 400
        readonly property int large: 600
        readonly property int extraLarge: 1000
        readonly property int expressiveFastSpatial: 350
        readonly property int expressiveDefaultSpatial: 500
        readonly property int expressiveEffects: 200
      }
    }

    readonly property QtObject widget: QtObject {
      readonly property real size: 32
      readonly property real sliderWidth: 200
    }
  }

  readonly property QtObject bar: QtObject {
    readonly property int innerHeight: 32
    readonly property int trayMenuWidth: 300
    readonly property int batteryWidth: 400
    readonly property int audioWidth: 400
    readonly property int networkWidth: 480
    readonly property int brightnessWidth: 400
    readonly property int calendarWidth: 360
  }

  readonly property QtObject launcher: QtObject {
    readonly property int itemWidth: 600
    readonly property int itemHeight: 52
    readonly property int wallpaperWidth: 280
    readonly property int wallpaperHeight: 200
  }

  readonly property QtObject lock: QtObject {
    readonly property real heightMult: 0.7
    readonly property real ratio: 16 / 9
    readonly property int centerWidth: 520
  }

  readonly property QtObject notifications: QtObject {
    readonly property int width: 400
    readonly property int image: 40
    readonly property int badge: 20
  }

  readonly property QtObject session: QtObject {
    readonly property int button: 80
  }

  readonly property QtObject settings: QtObject {
    readonly property real heightMult: 0.7
    readonly property real ratio: 16 / 9
    readonly property int centerWidth: 520
  }
}
