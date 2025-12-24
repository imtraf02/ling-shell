import Quickshell.Io

JsonObject {
  property int maxShown: 7
  property string specialPrefix: "@"
  property string actionPrefix: ">"
  property list<string> hiddenApps: []
  property Sizes sizes: Sizes {}
  property int maxWallpapers: 5 // Warning: even numbers look bad

  component Sizes: JsonObject {
    property int itemWidth: 600
    property int itemHeight: 52
    property int wallpaperWidth: 280
    property int wallpaperHeight: 200
  }
}
