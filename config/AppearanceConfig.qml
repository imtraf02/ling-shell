import Quickshell.Io

JsonObject {
  property Rounding rounding: Rounding {}
  property Spacing spacing: Spacing {}
  property Padding padding: Padding {}
  property FontStuff font: FontStuff {}
  property Anim anim: Anim {}
  property Widget widget: Widget {}

  component Rounding: JsonObject {
    property int small: 12
    property int normal: 17
    property int large: 25
    property int full: 1000
  }

  component Spacing: JsonObject {
    property int small: 6
    property int smaller: 8
    property int normal: 12
    property int larger: 16
    property int large: 20
  }

  component Padding: JsonObject {
    property int small: 4
    property int smaller: 6
    property int normal: 8
    property int larger: 10
    property int large: 14
  }

  component FontFamily: JsonObject {
    property string sans: "Rubik"
    property string mono: "CaskaydiaCove NF"
    property string clock: "Rubik"
  }

  component FontSize: JsonObject {
    property int small: 8
    property int smaller: 9
    property int normal: 10
    property int larger: 12
    property int large: 14
    property int extraLarge: 24
  }

  component FontStuff: JsonObject {
    property FontFamily family: FontFamily {}
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
    property real size: 32
    property real sliderWidth: 200
  }
}
