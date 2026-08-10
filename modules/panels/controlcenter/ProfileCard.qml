import QtQuick
import QtQuick.Layouts
import qs.common
import qs.widgets
import qs.services
import qs.utils

IBox {
  id: root

  required property var panel

  property string uptimeText: "--"
  readonly property bool uptimeVisible: root.panel?.isPanelOpen === true

  function uptimeConsumerId() {
    return "control-center-" + (root.panel?.screen?.name || "unknown");
  }

  onUptimeVisibleChanged: DistroService.setUptimeConsumer(uptimeConsumerId(), uptimeVisible)
  Component.onCompleted: DistroService.setUptimeConsumer(uptimeConsumerId(), uptimeVisible)
  Component.onDestruction: DistroService.setUptimeConsumer(uptimeConsumerId(), false)

  RowLayout {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.margins: Style.padding.small
    spacing: Style.spacing.small

    IImageCircled {
      Layout.preferredWidth: Math.round(Style.widget.size * 1.25)
      Layout.preferredHeight: Math.round(Style.widget.size * 1.25)
      imagePath: FileUtils.trimFileProtocol(Settings.general.avatarImage)
      fallbackIcon: "person"
      borderColor: ThemeService.palette.mPrimary
      borderWidth: 1
    }

    ColumnLayout {
      Layout.fillWidth: true
      IText {
        text: DistroService.user
        font.capitalization: Font.Capitalize
      }
      IText {
        text: "Uptime: " + DistroService.uptime
        font.pointSize: Style.font.size.small
        color: ThemeService.palette.mOutline
      }
    }

    RowLayout {
      spacing: Style.spacing.small
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      Item {
        Layout.fillWidth: true
      }

      IIconButton {
        icon: "settings"
        size: Style.widget.size * 0.8
        onClicked: {
          PanelService.getPanel("panel:settings", root.panel.screen).open();
        }
      }

      IIconButton {
        icon: "power_settings_new"
        size: Style.widget.size * 0.8

        onClicked: {
          PanelService.getPanel("panel:session", root.panel.screen).open();
        }
      }

      IIconButton {
        icon: "close"
        size: Style.widget.size * 0.8
        onClicked: {
          root.panel.close();
        }
      }
    }
  }
}
