pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.widgets
import qs.services
import qs.common

Rectangle {
  id: root

  required property NotificationService.Notif modelData
  required property PersistentProperties props
  required property bool expanded

  readonly property IText body: expandedContent.item?.body ?? null
  implicitHeight: expanded ? summary.implicitHeight + expandedContent.implicitHeight + expandedContent.anchors.topMargin + Style.padding.small * 2 : summaryHeightMetrics.height

  radius: Style.rounding.small
  color: {
    const c = root.modelData.urgency === "critical" ? ThemeService.palette.mSecondary : ThemeService.palette.mSurfaceContainerHigh;
    return expanded ? c : Qt.alpha(c, 0);
  }

  states: State {
    name: "expanded"
    when: root.expanded

    PropertyChanges {
      summary.anchors.margins: Style.padding.small
      dummySummary.anchors.margins: Style.padding.small
      compactBody.anchors.margins: Style.padding.small
      timeStr.anchors.margins: Style.padding.small
      expandedContent.anchors.margins: Style.padding.small
      summary.width: root.width - Style.padding.small * 2 - timeStr.implicitWidth - Style.spacing.small
      summary.maximumLineCount: Number.MAX_SAFE_INTEGER
    }
  }

  transitions: Transition {
    IAnim {
      properties: "margins,width,maximumLineCount"
    }
  }

  TextMetrics {
    id: summaryHeightMetrics

    font: summary.font
    text: " " // Use this height to prevent weird characters from changing the line height
  }

  IText {
    id: summary

    anchors.top: parent.top
    anchors.left: parent.left

    width: parent.width
    text: root.modelData.summary
    color: root.modelData.urgency === "critical" ? ThemeService.palette.mOnSecondary : ThemeService.palette.mOnSurface
    elide: Text.ElideRight
    wrapMode: Text.WordWrap
    maximumLineCount: 1
  }

  IText {
    id: dummySummary

    anchors.top: parent.top
    anchors.left: parent.left

    visible: false
    text: root.modelData.summary
  }

  WrappedLoader {
    id: compactBody

    shouldBeActive: !root.expanded
    anchors.top: parent.top
    anchors.left: dummySummary.right
    anchors.right: parent.right
    anchors.leftMargin: Style.spacing.small

    sourceComponent: IText {
      text: root.modelData.body.replace(/\n/g, " ")
      color: root.modelData.urgency === "critical" ? ThemeService.palette.mSecondary : ThemeService.palette.mOutline
      elide: Text.ElideRight
    }
  }

  WrappedLoader {
    id: timeStr

    shouldBeActive: root.expanded
    anchors.top: parent.top
    anchors.right: parent.right

    sourceComponent: IText {
      animate: true
      text: root.modelData.timeStr
      color: ThemeService.palette.mOutline
      font.pointSize: Style.font.size.small
    }
  }

  WrappedLoader {
    id: expandedContent

    shouldBeActive: root.expanded
    anchors.top: summary.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.topMargin: Style.spacing.small / 2

    sourceComponent: ColumnLayout {
      readonly property alias body: body

      spacing: Style.spacing.smaller

      IText {
        id: body

        Layout.fillWidth: true
        textFormat: Text.MarkdownText
        text: root.modelData.body.replace(/(.)\n(?!\n)/g, "$1\n\n") || qsTr("No body here! :/")
        color: root.modelData.urgency === "critical" ? ThemeService.palette.mSecondary : ThemeService.palette.mOutline
        wrapMode: Text.WordWrap

        onLinkActivated: link => {
          Quickshell.execDetached(["app2unit", "-O", "--", link]);
          PanelService.openedPanel.close();
        }
      }

      NotificationActionList {
        notif: root.modelData
      }
    }
  }

  component WrappedLoader: Loader {
    required property bool shouldBeActive

    opacity: shouldBeActive ? 1 : 0
    active: opacity > 0

    Behavior on opacity {
      IAnim {}
    }
  }
}
