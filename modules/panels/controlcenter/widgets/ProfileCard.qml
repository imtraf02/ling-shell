import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.widgets
import qs.services
import qs.utils
import qs.modules.panels.settings as SettingsPanel

IBox {
  id: root

  required property var panel
  required property int padding
  required property int spacing

  property string uptimeText: "--"

  RowLayout {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.margins: root.padding
    spacing: root.spacing

    IImageCircled {
      Layout.preferredWidth: Math.round(Style.appearance.widget.size * 1.25)
      Layout.preferredHeight: Math.round(Style.appearance.widget.size * 1.25)
      imagePath: FileUtils.trimFileProtocol(Settings.general.avatarImage)
      fallbackIcon: "person"
      borderColor: ThemeService.palette.mPrimary
      borderWidth: 1
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: root.spacing
      IText {
        text: DistroService.user
        font.capitalization: Font.Capitalize
      }
      IText {
        text: "Uptime: " + DistroService.uptime
        pointSize: Style.appearance.font.size.small
        color: ThemeService.palette.mOutline
      }
    }

    RowLayout {
      spacing: root.spacing
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      Item {
        Layout.fillWidth: true
      }

      IIconButton {
        icon: "settings"
        onClicked: {
          const settingsPanel = VisibilityService.getPanel("settings", root.panel.screen);
          settingsPanel.requestedTab = SettingsPanel.Panel.System;
          settingsPanel.open();
        }
      }

      IIconButton {
        icon: "power_settings_new"
        onClicked: {
          VisibilityService.getPanel("session", root.panel.screen).open();
        }
      }

      IIconButton {
        icon: "close"
        onClicked: {
          root.panel.close();
        }
      }
    }
  }
}
