pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.commons
import qs.widgets
import qs.services
import qs.utils

ColumnLayout {
  id: root

  required property var panel

  property var themeColorsCache: ({})
  property int cacheVersion: 0
  property string specificFolderMonitorName: ""

  property int padding: Config.appearance.padding.normal
  property string wallpaperPath: WallpaperService.getWallpaper(panel.screen.name)

  spacing: Config.appearance.spacing.larger

  function themeLoaded(themeName, jsonData) {
    const value = jsonData || {};
    themeColorsCache[themeName] = value;
    cacheVersion++;
  }

  function getThemeColor(theme, key) {
    const _ = cacheVersion;
    if (themeColorsCache[theme]?.[key]) {
      return themeColorsCache[theme][key];
    }
    return ThemeService.palette[key];
  }

  Connections {
    target: ThemeService
    function onThemeFilesChanged() {
      root.themeColorsCache = {};
      root.cacheVersion++;
    }
  }

  Connections {
    target: WallpaperService
    function onWallpaperChanged() {
      root.wallpaperPath = WallpaperService.getWallpaper(root.panel.screen.name);
    }
  }

  ILabel {
    label: "Wallpapers"
    description: "Customize your desktop background."
    labelSize: Config.appearance.font.size.large
    descriptionSize: Config.appearance.font.size.smaller
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: root.spacing

    ClippingRectangle {
      Layout.preferredWidth: 160
      Layout.preferredHeight: 90
      radius: Settings.appearance.cornerRadius
      color: ThemeService.palette.mSurfaceVariant
      Layout.alignment: Qt.AlignTop

      IImageCached {
        id: wallpaperImage
        anchors.fill: parent
        maxCacheDimension: 160
        imagePath: root.wallpaperPath
        cacheFolder: Directories.shellCacheWallpaperDir
      }

      IStateLayer {
        color: ThemeService.palette.mSurface
        function onClicked() {
          wallpaperPicker.openFilePicker();
        }
      }
    }

    ColumnLayout {
      spacing: Config.appearance.spacing.small
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignTop

      IText {
        Layout.fillWidth: true
        text: root.wallpaperPath.split("/").pop() + " (" + root.panel.screen.name + ")" || "No wallpaper selected"
        pointSize: Config.appearance.font.size.larger
        maximumLineCount: 1
      }

      ITextInputButton {
        label: "Wallpaper folder"
        description: "Path to your main wallpaper folder."
        text: Settings.wallpaper.directory
        buttonIcon: "folder_open"
        Layout.fillWidth: true
        onInputEditingFinished: Settings.wallpaper.directory = text
        onButtonClicked: wallpaperFolderPicker.open()
      }

      IToggle {
        label: "Recursive search"
        description: "Search subdirectories for wallpapers."
        checked: Settings.wallpaper.recursiveSearch
        onToggled: checked => Settings.wallpaper.recursiveSearch = checked
      }

      IToggle {
        label: "Set wallpaper on all monitors"
        description: "Use the same wallpaper on all monitors."
        checked: Settings.wallpaper.setWallpaperOnAllMonitors
        onToggled: checked => Settings.wallpaper.setWallpaperOnAllMonitors = checked
      }

      IToggle {
        label: "Monitor-specific directories"
        description: "Set a different wallpaper folder for each monitor."
        checked: Settings.wallpaper.enableMultiMonitorDirectories
        onToggled: checked => Settings.wallpaper.enableMultiMonitorDirectories = checked
      }

      IBox {
        visible: Settings.wallpaper.enableMultiMonitorDirectories

        Layout.fillWidth: true
        implicitHeight: contentCol.implicitHeight + contentCol.anchors.margins * 2

        ColumnLayout {
          id: contentCol
          anchors.fill: parent
          anchors.margins: root.padding
          spacing: Config.appearance.spacing.small

          Repeater {
            model: Quickshell.screens || []
            delegate: ColumnLayout {
              id: monitorLayout
              required property ShellScreen modelData

              Layout.fillWidth: true
              spacing: Config.appearance.spacing.small

              IText {
                text: (monitorLayout.modelData.name || "Unknown")
                color: ThemeService.palette.mPrimary
                font.weight: Font.DemiBold
              }

              ITextInputButton {
                text: WallpaperService.getMonitorDirectory(monitorLayout.modelData.name)
                buttonIcon: "folder_open"
                Layout.fillWidth: true
                onInputEditingFinished: WallpaperService.setMonitorDirectory(monitorLayout.modelData.name, text)
                onButtonClicked: {
                  root.specificFolderMonitorName = monitorLayout.modelData.name;
                  monitorFolderPicker.open();
                }
              }
            }
          }
        }
      }
    }
  }

  IFilePicker {
    id: wallpaperPicker
    title: "Select wallpaper"
    selectionMode: "files"
    initialPath: FileUtils.trimFileProtocol(Settings.wallpaper.directory) || Quickshell.env("HOME")
    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.pnm", "*.bmp"]
    onAccepted: paths => {
      if (paths.length > 0) {
        WallpaperService.changeWallpaper(paths[0], root.panel.screen.name);
      }
    }
  }

  IFilePicker {
    id: monitorFolderPicker
    selectionMode: "folders"
    title: "Monitor folder"
    initialPath: WallpaperService.getMonitorDirectory(root.specificFolderMonitorName) || Quickshell.env("HOME") + "/Pictures"
    onAccepted: paths => {
      if (paths.length > 0) {
        WallpaperService.setMonitorDirectory(root.specificFolderMonitorName, paths[0]);
      }
    }
  }

  IFilePicker {
    id: wallpaperFolderPicker
    selectionMode: "folders"
    title: "Wallpaper folder"
    initialPath: Settings.wallpaper.directory || Quickshell.env("HOME") + "/Pictures"
    onAccepted: paths => {
      if (paths.length > 0) {
        Settings.wallpaper.directory = paths[0];
      }
    }
  }

  IDivider {
    Layout.fillWidth: true
    Layout.topMargin: root.padding
    Layout.bottomMargin: root.padding
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: root.spacing

    ILabel {
      label: "Theme source"
      description: "Main settings for themes."
      labelSize: Config.appearance.font.size.large
      descriptionSize: Config.appearance.font.size.smaller
    }

    IToggle {
      label: "Dark mode"
      description: "Switches to a darker theme for easier viewing at night."
      enabled: !ThemeService.loading
      checked: Settings.appearance.theme.mode === "dark"
      onToggled: checked => {
        Settings.appearance.theme.mode = checked ? "dark" : "light";
      }
    }

    IToggle {
      label: "Use wallpaper colors"
      description: "Uses the colors from your wallpaper as a theme."
      enabled: ProgramCheckerService.matugenAvailable && !ThemeService.loading
      checked: Settings.appearance.theme.dynamic
      onToggled: checked => {
        Settings.appearance.theme.dynamic = checked;
      }
    }

    IComboBox {
      label: "Matugen scheme type"
      description: "Choose the color generation strategy used by Matugen to derive the dynamic theme palette."
      enabled: Settings.appearance.theme.dynamic
      opacity: Settings.appearance.theme.dynamic ? 1.0 : 0.6
      visible: Settings.appearance.theme.dynamic

      model: [
        {
          "key": "scheme-content",
          "name": "Content"
        },
        {
          "key": "scheme-expressive",
          "name": "Expressive"
        },
        {
          "key": "scheme-fidelity",
          "name": "Fidelity"
        },
        {
          "key": "scheme-fruit-salad",
          "name": "Fruit Salad"
        },
        {
          "key": "scheme-monochrome",
          "name": "Monochrome"
        },
        {
          "key": "scheme-neutral",
          "name": "Neutral"
        },
        {
          "key": "scheme-rainbow",
          "name": "Rainbow"
        },
        {
          "key": "scheme-tonal-spot",
          "name": "Tonal Spot"
        },
        {
          "key": "scheme-vibrant",
          "name": "Vibrant"
        }
      ]

      currentKey: Settings.appearance.theme.matugenType

      onSelected: key => {
        Settings.appearance.theme.matugenType = key;
      }
    }
  }

  IDivider {
    Layout.fillWidth: true
    Layout.topMargin: root.padding
    Layout.bottomMargin: root.padding
    visible: !Settings.appearance.theme.dynamic
  }

  ColumnLayout {
    spacing: root.spacing
    Layout.fillWidth: true
    visible: !Settings.appearance.theme.dynamic

    ILabel {
      label: "Themes"
      description: "Choose and manage color themes for the interface"
    }

    GridLayout {
      columns: 2
      rowSpacing: root.spacing
      columnSpacing: root.spacing
      Layout.fillWidth: true

      Repeater {
        model: ThemeService.themeFiles

        Rectangle {
          id: themeItem

          required property string modelData

          property string themePath: modelData
          property string themeName: ThemeService.getDisplayName(modelData)

          Layout.fillWidth: true
          Layout.alignment: Qt.AlignHCenter
          color: root.getThemeColor(themeName, "mSurface")
          height: 48
          radius: Settings.appearance.cornerRadius
          border.width: 3
          border.color: {
            if (Settings.appearance.theme[Settings.appearance.theme.mode] === themeName) {
              return ThemeService.palette.mSecondary;
            }
            if (itemMouseArea.containsMouse) {
              return ThemeService.palette.mPrimary;
            }
            return ThemeService.palette.mOutline;
          }

          RowLayout {
            id: theme
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: root.spacing

            property int diameter: 16

            IText {
              text: themeItem.themeName
              color: root.getThemeColor(themeItem.themeName, "mOnSurface")
              Layout.fillWidth: true
              elide: Text.ElideRight
              verticalAlignment: Text.AlignVCenter
              wrapMode: Text.WordWrap
              maximumLineCount: 1
            }

            Rectangle {
              Layout.preferredWidth: theme.diameter
              Layout.preferredHeight: theme.diameter
              radius: theme.diameter * 0.5
              color: root.getThemeColor(themeItem.themeName, "mPrimary")
            }

            Rectangle {
              Layout.preferredWidth: theme.diameter
              Layout.preferredHeight: theme.diameter
              radius: theme.diameter * 0.5
              color: root.getThemeColor(themeItem.themeName, "mSecondary")
            }

            Rectangle {
              Layout.preferredWidth: theme.diameter
              Layout.preferredHeight: theme.diameter
              radius: theme.diameter * 0.5
              color: root.getThemeColor(themeItem.themeName, "mTertiary")
            }

            Rectangle {
              Layout.preferredWidth: theme.diameter
              Layout.preferredHeight: theme.diameter
              radius: theme.diameter * 0.5
              color: root.getThemeColor(themeItem.themeName, "mError")
            }
          }

          MouseArea {
            id: itemMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Settings.appearance.theme[Settings.appearance.theme.mode] = themeItem.themeName;
            }
          }

          Rectangle {
            visible: (Settings.appearance.theme[Settings.appearance.theme.mode] === themeItem.themeName)
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -3
            anchors.rightMargin: 0
            width: 20
            height: 20
            radius: width * 0.5
            color: ThemeService.palette.mSecondary
            border.width: 1
            border.color: ThemeService.palette.mOnSecondary

            IIcon {
              icon: "check"
              color: ThemeService.palette.mOnSecondary
              anchors.centerIn: parent
            }
          }

          Behavior on border.color {
            ICAnim {}
          }

          FileView {
            path: themeItem.modelData
            blockLoading: false
            onLoaded: {
              const themeName = ThemeService.getDisplayName(path);

              try {
                const jsonData = JSON.parse(text());
                root.themeLoaded(themeName, jsonData);
              } catch (e) {
                root.themeLoaded(themeName, null);
              }
            }
          }
        }
      }
    }
  }

  IDivider {
    Layout.fillWidth: true
    Layout.topMargin: root.padding
    Layout.bottomMargin: root.padding
  }

  ISpinBox {
    Layout.fillWidth: true
    label: "Thickness"
    description: "Thickness of the screen margin used to wrap the drawer and masked regions"
    minimum: 0
    maximum: 20
    value: Settings.appearance.thickness
    stepSize: 1
    onValueChanged: Settings.appearance.thickness = value
  }

  ISpinBox {
    Layout.fillWidth: true
    label: "Corner radius"
    description: "Corner roundness applied to the drawer, widgets and masked screen areas"
    minimum: 0
    maximum: 20
    value: Settings.appearance.cornerRadius
    stepSize: 1
    onValueChanged: Settings.appearance.cornerRadius = value
  }

  IDivider {
    Layout.fillWidth: true
    Layout.topMargin: root.padding
    Layout.bottomMargin: root.padding
  }

  ILabel {
    label: "UI font"
    description: "Font used for the interface elements."
    labelSize: Config.appearance.font.size.large
    descriptionSize: Config.appearance.font.size.smaller
  }

  ISearchableComboBox {
    label: "Sans-serif font"
    description: "Primary font used for UI text."
    model: FontService.availableFonts
    currentKey: Settings.appearance.font.sans
    placeholder: "Select sans-serif font…"
    searchPlaceholder: "Search fonts…"
    popupHeight: 420
    minimumWidth: 300
    onSelected: key => {
      Settings.appearance.font.sans = key;
    }
  }

  ISearchableComboBox {
    label: "Monospace font"
    description: "Font used for code, terminals, and technical text."
    model: FontService.availableFonts
    currentKey: Settings.appearance.font.mono
    placeholder: "Select monospace font…"
    searchPlaceholder: "Search fonts…"
    popupHeight: 420
    minimumWidth: 300
    onSelected: key => {
      Settings.appearance.font.mono = key;
    }
  }

  ISearchableComboBox {
    label: "Clock font"
    description: "Font used for the clock."
    model: FontService.availableFonts
    currentKey: Settings.appearance.font.clock
    placeholder: "Select clock font…"
    searchPlaceholder: "Search fonts…"
    popupHeight: 420
    minimumWidth: 300
    onSelected: key => {
      Settings.appearance.font.clock = key;
    }
  }

  ISpinBox {
    Layout.fillWidth: true
    label: "Font weight"
    description: "Weight of the font used for the interface elements."
    from: 300
    to: 900
    stepSize: 100
    value: Settings.appearance.font.weight
    onValueChanged: {
      Settings.appearance.font.weight = value;
    }
  }

  ISpinBox {
    Layout.fillWidth: true
    label: "Font scale"
    description: "Scale of the font used for the interface elements."
    from: 0.75
    to: 1.25
    stepSize: 0.01
    value: Settings.appearance.font.scale
    onValueChanged: {
      Settings.appearance.font.scale = value;
    }
  }

  IDivider {
    Layout.fillWidth: true
    Layout.topMargin: root.padding
    Layout.bottomMargin: root.padding
  }
}
