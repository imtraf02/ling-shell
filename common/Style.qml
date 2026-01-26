pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {

  component Rounding: JsonObject {
    property int small: 12
    property int normal: 17
    property int large: 25
    property int full: 1000
  }

  component Spacing: JsonObject {
    property int small: 7
    property int smaller: 10
    property int normal: 12
    property int larger: 15
    property int large: 20
  }

  component Padding: JsonObject {
    property int small: 5
    property int smaller: 7
    property int normal: 10
    property int larger: 12
    property int large: 15
  }

  component FontSize: JsonObject {
    property int small: 11
    property int smaller: 12
    property int normal: 13
    property int larger: 15
    property int large: 18
    property int extraLarge: 28
  }

  component FontStuff: JsonObject {
    property FontSize size: FontSize {}
  }

  component AnimCurves: JsonObject {
    property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
    property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    property list<real> standard: [0.2, 0, 0, 1, 1, 1]
    property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
    property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
    property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
    property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
    property list<real> expressiveEffects: [0.34, 0.8, 0.34, 1, 1, 1]
  }

  component AnimDurations: JsonObject {
    property int small: 200
    property int normal: 400
    property int large: 600
    property int extraLarge: 1000
    property int expressiveFastSpatial: 350
    property int expressiveDefaultSpatial: 500
    property int expressiveEffects: 200
  }

  component Anim: JsonObject {
    property AnimCurves curves: AnimCurves {}
    property AnimDurations durations: AnimDurations {}
  }

  component Widget: JsonObject {
    property real size: 33
    property real sliderWidth: 200
  }

  component Bar: JsonObject {
    property int innerHeight: 33
    property int trayMenuWidth: 300
    property int batteryWidth: 400
    property int audioWidth: 400
    property int networkWidth: 480
    property int brightnessWidth: 400
    property int calendarWidth: 360
    property int mediaWidth: 360
    property int controlCenterWidth: 420
    property int notificationsWidth: 480
  }

  component Shadow: JsonObject {
    property real opacity: 0.85
    property real blur: 1.0
    property int blurMax: 22
    property real horizontalOffset: 2
    property real verticalOffset: 3
  }

  component Launcher: JsonObject {
    property int itemWidth: 600
    property int itemHeight: 52
    property int wallpaperWidth: 280
    property int wallpaperHeight: 200
  }

  component Lock: JsonObject {
    property real heightMult: 0.7
    property real ratio: 16 / 9
    property int centerWidth: 560
  }

  component Notifications: JsonObject {
    property int width: 400
    property int image: 40
    property int badge: 20
  }

  component Session: JsonObject {
    property int button: 80
  }

  component Settings: JsonObject {
    property int width: 1280
    property int height: 720
  }

  property Rounding rounding: Rounding {}
  property Spacing spacing: Spacing {}
  property Padding padding: Padding {}
  property FontStuff font: FontStuff {}
  property Anim anim: Anim {}
  property Widget widget: Widget {}
  property Bar bar: Bar {}
  property Shadow shadow: Shadow {}
  property Launcher launcher: Launcher {}
  property Lock lock: Lock {}
  property Notifications notifications: Notifications {}
  property Session session: Session {}
  property Settings settings: Settings {}
}
