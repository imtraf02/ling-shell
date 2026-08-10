import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

ColumnLayout {
  id: root
  spacing: Style.spacing.normal
  Component.onCompleted: ProgramCheckerService.ensure("matugenAvailable")

  function themeModel() {
    const themes = [];
    for (let i = 0; i < ThemeService.themeFiles.length; i++) {
      const name = ThemeService.getDisplayName(ThemeService.themeFiles[i]);
      themes.push({ key: name, name: name });
    }
    return themes;
  }

  SettingsPage {
    title: "Appearance"
    description: "Color, geometry, and typography for Ling Shell."
    icon: "palette"
    sectionId: "appearance"

    SettingsCardGrid {
      id: grid
      SettingsCard {
        title: "Theme preview"
        description: "Changes apply immediately to the shell palette."
        icon: "palette"
        Layout.columnSpan: grid.columns
        IBox {
          Layout.fillWidth: true
          implicitHeight: 88
          color: ThemeService.palette.mSurfaceVariant
          RowLayout {
            anchors.fill: parent
            anchors.margins: Style.padding.normal
            spacing: Style.spacing.small
            Repeater {
              model: [ThemeService.palette.mPrimary, ThemeService.palette.mSecondary, ThemeService.palette.mTertiary, ThemeService.palette.mError]
              delegate: Rectangle {
                required property color modelData
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: Style.rounding.full
                color: modelData
              }
            }
            Item { Layout.fillWidth: true }
            IText { text: Settings.appearance.theme.dynamic ? "Dynamic palette" : (Settings.appearance.theme.mode === "dark" ? Settings.appearance.theme.dark : Settings.appearance.theme.light); font.weight: Font.Medium }
          }
        }
        SettingsChoiceGroup { label: "Color mode"; currentKey: Settings.appearance.theme.mode; model: [{ key: "light", name: "Light", icon: "light_mode" }, { key: "dark", name: "Dark", icon: "dark_mode" }]; onSelected: key => Settings.appearance.theme.mode = key }
        IToggle { label: "Dynamic colors"; description: "Generate colors from the active wallpaper with Matugen."; checked: Settings.appearance.theme.dynamic; onToggled: checked => Settings.appearance.theme.dynamic = checked }
        SettingsNotice { visible: Settings.appearance.theme.dynamic && ProgramCheckerService.isChecked("matugenAvailable") && !ProgramCheckerService.matugenAvailable; warning: true; icon: "extension_off"; text: "Matugen is bundled by default. Rebuild the package if it is unavailable." }
        IComboBox { visible: !Settings.appearance.theme.dynamic; label: "Light theme"; currentKey: Settings.appearance.theme.light; model: root.themeModel(); placeholder: "No themes found"; onSelected: key => Settings.appearance.theme.light = key }
        IComboBox { visible: !Settings.appearance.theme.dynamic; label: "Dark theme"; currentKey: Settings.appearance.theme.dark; model: root.themeModel(); placeholder: "No themes found"; onSelected: key => Settings.appearance.theme.dark = key }
        IComboBox { visible: Settings.appearance.theme.dynamic; label: "Matugen scheme"; currentKey: Settings.appearance.theme.matugenType; model: ThemeService.validMatugenSchemes.map(scheme => ({ key: scheme, name: scheme.replace("scheme-", "") })); onSelected: key => Settings.appearance.theme.matugenType = key }
      }
      SettingsCard {
        title: "Geometry"
        description: "Frame and corner treatment."
        icon: "rounded_corner"
        SettingsSpinRow { label: "Border thickness"; value: Settings.appearance.thickness; from: 0; to: 32; suffix: " px"; onChanged: value => Settings.appearance.thickness = value }
        SettingsSpinRow { label: "Corner radius"; value: Settings.appearance.cornerRadius; from: 0; to: 64; suffix: " px"; onChanged: value => Settings.appearance.cornerRadius = value }
      }
      SettingsCard {
        title: "Typography"
        description: "Installed font family names."
        icon: "text_fields"
        ITextInput { label: "Interface font"; text: Settings.appearance.font.sans; onEditingFinished: Settings.appearance.font.sans = text }
        ITextInput { label: "Monospace font"; text: Settings.appearance.font.mono; onEditingFinished: Settings.appearance.font.mono = text }
        ITextInput { label: "Clock font"; text: Settings.appearance.font.clock; onEditingFinished: Settings.appearance.font.clock = text }
      }
    }
  }
}
