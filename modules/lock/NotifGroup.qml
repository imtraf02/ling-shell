pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.services
import qs.utils
import qs.widgets

Rectangle {
  id: root

  required property string modelData

  readonly property list<var> notifs: NotificationService.list.filter(notif => notif.appName === modelData)
  readonly property string image: notifs.find(n => n.image.length > 0)?.image ?? ""
  readonly property string appIcon: notifs.find(n => n.appIcon.length > 0)?.appIcon ?? ""
  readonly property string urgency: notifs.some(n => n.urgency === NotificationUrgency.Critical) ? "critical" : notifs.some(n => n.urgency === NotificationUrgency.Normal) ? "normal" : "low"
  readonly property real padding: Style.appearance.padding.normal
  readonly property real spacing: Style.appearance.spacing.small

  property bool expanded

  anchors.left: parent?.left
  anchors.right: parent?.right
  implicitHeight: content.implicitHeight + root.padding * 2

  clip: true
  radius: Style.appearance.rounding.normal
  color: root.urgency === "critical" ? ThemeService.palette.mSecondary : ThemeService.palette.mSurfaceContainerHigh

  RowLayout {
    id: content

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: root.padding

    spacing: root.spacing

    Item {
      Layout.alignment: Qt.AlignLeft | Qt.AlignTop
      implicitWidth: Style.notifications.image
      implicitHeight: Style.notifications.image

      Component {
        id: imageComp

        Image {
          source: Qt.resolvedUrl(root.image)
          fillMode: Image.PreserveAspectCrop
          cache: false
          asynchronous: true
          width: Style.notifications.image
          height: Style.notifications.image
        }
      }

      Component {
        id: appIconComp

        IColouredIcon {
          implicitSize: Math.round(Style.notifications.image * 0.6)
          source: Quickshell.iconPath(root.appIcon)
          colour: root.urgency === "critical" ? ThemeService.palette.mOnError : root.urgency === "low" ? ThemeService.palette.mOnSurface : ThemeService.palette.mOnSecondary
          layer.enabled: root.appIcon.endsWith("symbolic")
        }
      }

      Component {
        id: materialIconComp

        IIcon {
          icon: Icons.getNotifIcon(root.notifs[0]?.summary, root.urgency)
          color: root.urgency === "critical" ? ThemeService.palette.mOnError : root.urgency === "low" ? ThemeService.palette.mOnSurface : ThemeService.palette.mOnSecondary
          font.pointSize: Style.appearance.font.size.large
        }
      }

      ClippingRectangle {
        anchors.fill: parent
        color: root.urgency === "critical" ? ThemeService.palette.mError : root.urgency === "low" ? ThemeService.palette.mSurfaceContainerHighest : ThemeService.palette.mSecondary
        radius: Style.appearance.rounding.full

        Loader {
          anchors.centerIn: parent
          asynchronous: true
          sourceComponent: root.image ? imageComp : root.appIcon ? appIconComp : materialIconComp
        }
      }

      Loader {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        asynchronous: true
        active: root.appIcon && root.image

        sourceComponent: Rectangle {
          implicitWidth: Style.notifications.badge
          implicitHeight: Style.notifications.badge

          color: root.urgency === "critical" ? ThemeService.palette.mError : root.urgency === "low" ? ThemeService.palette.mSurfaceContainerHighest : ThemeService.palette.mSecondary
          radius: Style.appearance.rounding.full

          IColouredIcon {
            anchors.centerIn: parent
            implicitSize: Math.round(Style.notifications.badge * 0.6)
            source: Quickshell.iconPath(root.appIcon)
            colour: root.urgency === "critical" ? ThemeService.palette.mOnError : root.urgency === "low" ? ThemeService.palette.mOnSurface : ThemeService.palette.mOnSecondary
            layer.enabled: root.appIcon.endsWith("symbolic")
          }
        }
      }
    }

    ColumnLayout {
      Layout.topMargin: -Style.appearance.padding.small
      Layout.bottomMargin: -Style.appearance.padding.small / 2 - (root.expanded ? 0 : spacing)
      Layout.fillWidth: true
      spacing: Math.round(Style.appearance.spacing.small / 2)

      RowLayout {
        Layout.bottomMargin: -parent.spacing
        Layout.fillWidth: true
        spacing: Style.appearance.spacing.smaller

        IText {
          Layout.fillWidth: true
          text: root.modelData
          color: ThemeService.palette.mOnSurfaceVariant
          font.pointSize: Style.appearance.font.size.small
          elide: Text.ElideRight
        }

        IText {
          animate: true
          text: root.notifs[0]?.timeStr ?? ""
          color: ThemeService.palette.mOutline
          font.pointSize: Style.appearance.font.size.small
        }

        Rectangle {
          implicitWidth: expandBtn.implicitWidth + Style.appearance.padding.smaller * 2
          implicitHeight: groupCount.implicitHeight + Style.appearance.padding.small

          color: root.urgency === "critical" ? ThemeService.palette.mError : ThemeService.palette.mSurfaceContainerHighest
          radius: Style.appearance.rounding.full

          opacity: root.notifs.length > Settings.notifications.groupPreviewNum ? 1 : 0
          Layout.preferredWidth: root.notifs.length > Settings.notifications.groupPreviewNum ? implicitWidth : 0

          IStateLayer {
            color: root.urgency === "critical" ? ThemeService.palette.mOnError : ThemeService.palette.mOnSurface

            function onClicked(): void {
              root.expanded = !root.expanded;
            }
          }

          RowLayout {
            id: expandBtn

            anchors.centerIn: parent
            spacing: Style.appearance.spacing.small / 2

            IText {
              id: groupCount

              Layout.leftMargin: Style.appearance.padding.small / 2
              animate: true
              text: root.notifs.length
              color: root.urgency === "critical" ? ThemeService.palette.mOnError : ThemeService.palette.mOnSurface
              font.pointSize: Style.appearance.font.size.small
            }

            IIcon {
              Layout.rightMargin: -Style.appearance.padding.small / 2
              animate: true
              icon: root.expanded ? "expand_less" : "expand_more"
              color: root.urgency === "critical" ? ThemeService.palette.mOnError : ThemeService.palette.mOnSurface
            }
          }

          Behavior on opacity {
            IAnim {}
          }

          Behavior on Layout.preferredWidth {
            IAnim {}
          }
        }
      }

      Repeater {
        model: ScriptModel {
          values: root.notifs.slice(0, Settings.notifications.groupPreviewNum)
        }

        NotifLine {
          id: notif

          ParallelAnimation {
            running: true

            IAnim {
              target: notif
              property: "opacity"
              from: 0
              to: 1
            }
            IAnim {
              target: notif
              property: "scale"
              from: 0.7
              to: 1
            }
            IAnim {
              target: notif.Layout
              property: "preferredHeight"
              from: 0
              to: notif.implicitHeight
            }
          }

          ParallelAnimation {
            running: notif.modelData.closed
            onFinished: notif.modelData.unlock(notif)

            IAnim {
              target: notif
              property: "opacity"
              to: 0
            }
            IAnim {
              target: notif
              property: "scale"
              to: 0.7
            }
            IAnim {
              target: notif.Layout
              property: "preferredHeight"
              to: 0
            }
          }
        }
      }

      Loader {
        Layout.fillWidth: true

        opacity: root.expanded ? 1 : 0
        Layout.preferredHeight: root.expanded ? implicitHeight : 0
        active: opacity > 0
        asynchronous: true

        sourceComponent: ColumnLayout {
          Repeater {
            model: ScriptModel {
              values: root.notifs.slice(Settings.notifications.groupPreviewNum)
            }

            NotifLine {}
          }
        }

        Behavior on opacity {
          IAnim {}
        }
      }
    }
  }

  Behavior on implicitHeight {
    IAnim {
      duration: Style.appearance.anim.durations.expressiveDefaultSpatial
      easing.bezierCurve: Style.appearance.anim.curves.expressiveDefaultSpatial
    }
  }

  component NotifLine: IText {
    id: notifLine

    required property NotificationService.Notif modelData

    Layout.fillWidth: true
    textFormat: Text.MarkdownText
    text: {
      const summary = modelData.summary.replace(/\n/g, " ");
      const body = modelData.body.replace(/\n/g, " ");
      const colour = root.urgency === "critical" ? ThemeService.palette.mSecondary : ThemeService.palette.mOutline;

      if (metrics.text === metrics.elidedText)
        return `${summary} <span style='color:${colour}'>${body}</span>`;

      const t = metrics.elidedText.length - 3;
      if (t < summary.length)
        return `${summary.slice(0, t)}...`;

      return `${summary} <span style='color:${colour}'>${body.slice(0, t - summary.length)}...</span>`;
    }
    color: root.urgency === "critical" ? ThemeService.palette.mOnSecondary : ThemeService.palette.mOnSurface

    Component.onCompleted: modelData.lock(this)
    Component.onDestruction: modelData.unlock(this)

    TextMetrics {
      id: metrics

      text: `${notifLine.modelData.summary} ${notifLine.modelData.body}`.replace(/\n/g, " ")
      font.pointSize: notifLine.font.pointSize
      font.family: notifLine.font.family
      elideWidth: notifLine.width
      elide: Text.ElideRight
    }
  }
}
