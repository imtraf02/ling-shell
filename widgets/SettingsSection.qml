import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

ColumnLayout {
  id: root

  property string title: ""
  property string description: ""
  property bool advanced: false
  property bool expanded: !advanced
  property bool resetEnabled: true
  property bool confirmingReset: false

  default property alias content: sectionContent.data

  signal resetRequested

  Layout.fillWidth: true
  spacing: Style.spacing.small

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.spacing.small

    IIconButton {
      visible: root.advanced
      icon: root.expanded ? "expand_less" : "expand_more"
      onClicked: root.expanded = !root.expanded
    }

    ILabel {
      label: root.title
      description: root.description
      Layout.fillWidth: true
    }

    IButton {
      visible: root.resetEnabled
      text: root.confirmingReset ? "Confirm reset" : "Reset"
      icon: root.confirmingReset ? "warning" : "restart_alt"
      outlined: !root.confirmingReset
      backgroundColor: root.confirmingReset ? ThemeService.palette.mError : ThemeService.palette.mPrimary
      textColor: root.confirmingReset ? ThemeService.palette.mOnError : ThemeService.palette.mOnPrimary
      onClicked: {
        if (root.confirmingReset) {
          root.confirmingReset = false;
          root.resetRequested();
        } else {
          root.confirmingReset = true;
          resetConfirmTimer.restart();
        }
      }
    }
  }

  ColumnLayout {
    id: sectionContent
    Layout.fillWidth: true
    visible: root.expanded
    opacity: visible ? 1.0 : 0.0
    spacing: Style.spacing.small

    Behavior on opacity { IAnim {} }
  }

  Timer {
    id: resetConfirmTimer
    interval: 3500
    onTriggered: root.confirmingReset = false
  }
}
