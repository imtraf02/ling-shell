import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

GridLayout {
  id: root

  readonly property real padding: Config.appearance.padding.normal
  readonly property real spacing: Config.appearance.spacing.small

  anchors.left: parent.left
  anchors.right: parent.right
  anchors.margins: padding

  rowSpacing: spacing
  columnSpacing: spacing
  rows: 2
  columns: 2

  PowerButton {
    Layout.topMargin: root.padding
    icon: "logout"
    text: "Logout"
    bgHoverColor: ThemeService.palette.mPrimary
    textHoverColor: ThemeService.palette.mOnPrimary
    onClicked: CompositorService.logout()
  }

  PowerButton {
    Layout.topMargin: root.padding
    icon: "pause"
    text: "Suspend"
    bgHoverColor: ThemeService.palette.mPrimary
    textHoverColor: ThemeService.palette.mOnPrimary
    onClicked: CompositorService.suspend()
  }

  PowerButton {
    Layout.bottomMargin: root.padding
    icon: "restart_alt"
    text: "Reboot"
    bgHoverColor: ThemeService.palette.mPrimary
    textHoverColor: ThemeService.palette.mOnPrimary
    onClicked: CompositorService.reboot()
  }

  PowerButton {
    Layout.bottomMargin: root.padding
    icon: "power_settings_new"
    text: "Shutdown"
    bgHoverColor: ThemeService.palette.mError
    textHoverColor: ThemeService.palette.mOnError
    onClicked: CompositorService.shutdown()
  }

  component PowerButton: Rectangle {
    id: powerButton

    required property string icon
    required property string text
    required property color bgHoverColor
    required property color textHoverColor

    Layout.fillWidth: true
    implicitHeight: 40
    radius: height / 2
    color: mouseArea.containsMouse ? bgHoverColor : ThemeService.palette.mSurfaceContainer
    border.color: Qt.alpha(ThemeService.palette.mOutline, 0.4)
    border.width: 1

    signal clicked

    Behavior on color {
      ICAnim {}
    }

    RowLayout {
      anchors.centerIn: parent
      spacing: 6

      IIcon {
        icon: powerButton.icon
        color: mouseArea.containsMouse ? powerButton.textHoverColor : ThemeService.palette.mOnSurfaceVariant

        Behavior on color {
          ICAnim {}
        }
      }

      IText {
        text: powerButton.text
        color: mouseArea.containsMouse ? powerButton.textHoverColor : ThemeService.palette.mOnSurfaceVariant

        Behavior on color {
          ICAnim {}
        }
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: parent.clicked()
    }
  }
}
