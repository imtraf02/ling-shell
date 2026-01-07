import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.commons
import qs.services
import qs.widgets

Rectangle {
  id: root

  property string icon: "skull"
  property string title: "Title"
  property string description: ""
  property bool isActive: false
  property bool enable: true

  readonly property int padding: Style.appearance.padding.normal
  readonly property int spacing: Style.appearance.spacing.small

  radius: Settings.appearance.cornerRadius
  color: enable ? (mouse.containsMouse ? ThemeService.palette.mSurfaceContainerHigh : ThemeService.palette.mSurfaceContainer) : Qt.alpha(ThemeService.palette.mSurfaceContainer, 0.5)
  border.color: Qt.alpha(ThemeService.palette.mOutline, enable ? 0.4 : 0.2)
  border.width: 1

  implicitHeight: content.implicitHeight + padding * 2
  opacity: enable ? 1.0 : 0.6

  signal clicked
  signal toggled

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: root.enable
    acceptedButtons: Qt.LeftButton
    enabled: root.enable

    onClicked: {
      if (root.enable) {
        root.clicked();
      }
    }

    RowLayout {
      id: content
      anchors.fill: parent
      anchors.margins: root.padding
      spacing: root.spacing

      Rectangle {
        implicitWidth: 40
        implicitHeight: 40
        radius: Settings.appearance.cornerRadius
        color: root.enable ? (root.isActive ? ThemeService.palette.mPrimary : tileMouse.containsMouse ? ThemeService.palette.mSurfaceContainer : ThemeService.palette.mSurface) : Qt.alpha(ThemeService.palette.mSurface, 0.5)
        border.color: Qt.alpha(ThemeService.palette.mOutline, root.enable ? 0.4 : 0.2)
        border.width: 1
        z: 1

        IIcon {
          anchors.centerIn: parent
          icon: root.icon
          color: root.enable ? (root.isActive ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface) : Qt.alpha(ThemeService.palette.mOnSurface, 0.5)
        }

        MouseArea {
          id: tileMouse
          anchors.fill: parent
          hoverEnabled: root.enable
          acceptedButtons: Qt.LeftButton
          enabled: root.enable
          propagateComposedEvents: true

          onClicked: {
            if (root.enable) {
              root.toggled();
            }
          }
        }
      }

      ColumnLayout {
        spacing: root.spacing

        IText {
          text: root.title
          Layout.fillWidth: true
          elide: Text.ElideRight
          maximumLineCount: 1
          color: root.enable ? ThemeService.palette.mOnSurface : Qt.alpha(ThemeService.palette.mOnSurface, 0.5)
        }

        IText {
          text: root.description
          Layout.fillWidth: true
          elide: Text.ElideRight
          maximumLineCount: 1
          pointSize: Style.appearance.font.size.small
          color: root.enable ? ThemeService.palette.mOutline : Qt.alpha(ThemeService.palette.mOutline, 0.5)
        }
      }

      Item {
        Layout.fillWidth: true
      }
    }
  }
}
