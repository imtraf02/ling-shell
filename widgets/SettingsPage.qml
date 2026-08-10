import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

ColumnLayout {
  id: root

  property string title: ""
  property string description: ""
  property string icon: "settings"
  property string sectionId: ""
  property bool resetEnabled: sectionId !== ""
  property bool confirmingReset: false

  default property alias content: pageContent.data

  Layout.fillWidth: true
  spacing: Style.spacing.normal

  IBox {
    Layout.fillWidth: true
    implicitHeight: pageHeader.implicitHeight + Style.padding.normal * 2
    color: ThemeService.palette.mSurfaceContainerHigh

    RowLayout {
      id: pageHeader
      anchors.fill: parent
      anchors.margins: Style.padding.normal
      spacing: Style.spacing.normal

      Rectangle {
        Layout.preferredWidth: Math.round(Style.widget.size * 1.45)
        Layout.preferredHeight: width
        radius: Style.rounding.small
        color: ThemeService.palette.mPrimaryContainer
        IIcon {
          anchors.centerIn: parent
          icon: root.icon
          font.pointSize: Style.font.size.extraLarge
          color: ThemeService.palette.mOnPrimaryContainer
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        IText {
          text: root.title
          font.pointSize: Style.font.size.large
          font.weight: Font.Medium
        }
        IText {
          Layout.fillWidth: true
          text: root.description
          color: ThemeService.palette.mOnSurfaceVariant
          wrapMode: Text.WordWrap
          font.pointSize: Style.font.size.small
        }
      }

      IButton {
        visible: root.resetEnabled
        text: root.confirmingReset ? "Confirm reset" : "Reset defaults"
        icon: root.confirmingReset ? "warning" : "restart_alt"
        outlined: !root.confirmingReset
        backgroundColor: root.confirmingReset ? ThemeService.palette.mError : ThemeService.palette.mPrimary
        textColor: root.confirmingReset ? ThemeService.palette.mOnError : ThemeService.palette.mOnPrimary
        onClicked: {
          if (root.confirmingReset) {
            root.confirmingReset = false;
            Settings.resetSection(root.sectionId);
          } else {
            root.confirmingReset = true;
            resetTimer.restart();
          }
        }
      }
    }
  }

  ColumnLayout {
    id: pageContent
    Layout.fillWidth: true
    spacing: Style.spacing.normal
  }

  Timer {
    id: resetTimer
    interval: 3500
    onTriggered: root.confirmingReset = false
  }
}
