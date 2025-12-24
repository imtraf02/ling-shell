import Quickshell.Io

JsonObject {
  property Sizes sizes: Sizes {}

  component Sizes: JsonObject {
    property int innerHeight: 32
    property int trayMenuWidth: 300
    property int batteryWidth: 400
    property int audioWidth: 400
    property int networkWidth: 480
    property int brightnessWidth: 400
    property int calendarWidth: 360
  }
}
