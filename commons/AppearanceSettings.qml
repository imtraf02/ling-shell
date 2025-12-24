import QtQuick
import Quickshell.Io

JsonObject {
  property int thickness: 4
  property int cornerRadius: 8
  property Theme theme: Theme {}
  property FontStuff font: FontStuff {}

  component FontStuff: JsonObject {
    property string sans: "Rubik"
    property string mono: "CaskaydiaCove NF"
    property string clock: "Rubik"
    property real scale: 1.0
    property int weight: Font.Normal
  }

  component Theme: JsonObject {
    property string mode: "light"
    property string light: "Ling Light"
    property string dark: "Ling Dark"
    property bool dynamic: false
    property string matugenType: "scheme-tonal-spot"
  }
}
