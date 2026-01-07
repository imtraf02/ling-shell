pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.commons
import qs.services
import qs.widgets

Rectangle {
  id: root

  required property string modelData
  required property Flickable container
  required property PersistentProperties props

  readonly property list<var> notifs: NotificationService.list.filter(n => n.appName === modelData)
  readonly property int notifCount: notifs.reduce((acc, n) => n.closed ? acc : acc + 1, 0)
  readonly property string image: notifs.find(n => !n.closed && n.image.length > 0)?.image ?? ""
  readonly property string appIcon: notifs.find(n => !n.closed && n.appIcon.length > 0)?.appIcon ?? ""
  readonly property int urgency: notifs.some(n => !n.closed && n.urgency === NotificationUrgency.Critical) ? NotificationUrgency.Critical : notifs.some(n => n.urgency === NotificationUrgency.Normal) ? NotificationUrgency.Normal : NotificationUrgency.Low

  readonly property bool expanded: props.expandedNotifs.includes(modelData)

  function toggleExpand(expand: bool): void {
    if (expand) {
      if (!expanded)
        props.expandedNotifs.push(modelData);
    } else if (expanded) {
      props.expandedNotifs.splice(props.expandedNotifs.indexOf(modelData), 1);
    }
  }

  Component.onDestruction: {
    if (notifCount === 0 && expanded)
      props.expandedNotifs.splice(props.expandedNotifs.indexOf(modelData), 1);
  }

  anchors.left: parent?.left
  anchors.right: parent?.right
  implicitHeight: content.implicitHeight + Style.appearance.padding.normal * 2

  clip: true
  radius: Settings.appearance.cornerRadius
  color: ThemeService.palette.mSurfaceContainer

  RowLayout {
    id: content

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.appearance.padding.normal

    spacing: Style.appearance.spacing.small

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
          colour: root.urgency === NotificationUrgency.Critical ? ThemeService.palette.mOnError : root.urgency === NotificationUrgency.Low ? ThemeService.palette.mOnSurface : ThemeService.palette.mOnSecondary

          layer.enabled: root.appIcon.endsWith("symbolic")
        }
      }

      Component {
        id: materialIconComp

        IIcon {
          icon: {
            let summary = root.notifs[0]?.summary || "";
            summary = summary.toLowerCase();
            if (summary.includes("reboot"))
              return "restart_alt";
            if (summary.includes("recording"))
              return "screen_record";
            if (summary.includes("battery"))
              return "power";
            if (summary.includes("screenshot"))
              return "screenshot_monitor";
            if (summary.includes("welcome"))
              return "waving_hand";
            if (summary.includes("time") || summary.includes("a break"))
              return "schedule";
            if (summary.includes("installed"))
              return "download";
            if (summary.includes("update"))
              return "update";
            if (summary.includes("unable to"))
              return "deployed_code_alert";
            if (summary.includes("profile"))
              return "person";
            if (summary.includes("file"))
              return "folder_copy";
            if (root.urgency === NotificationUrgency.Critical)
              return "release_alert";
            return "chat";
          }
          color: root.urgency === NotificationUrgency.Critical ? ThemeService.palette.mOnError : root.urgency === NotificationUrgency.Low ? ThemeService.palette.mOnSurface : ThemeService.palette.mOnSecondary

          font.pointSize: Style.appearance.font.size.large
        }
      }

      ClippingRectangle {
        anchors.fill: parent
        color: root.urgency === NotificationUrgency.Critical ? ThemeService.palette.mError : root.urgency === NotificationUrgency.Low ? ThemeService.palette.mSurfaceContainerHigh : Qt.alpha(ThemeService.palette.mSecondary, 0.4)
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

          color: root.urgency === NotificationUrgency.Critical ? ThemeService.palette.mError : root.urgency === NotificationUrgency.Low ? ThemeService.palette.mSurfaceContainerHigh : Qt.alpha(ThemeService.palette.mSecondary, 0.4)
          radius: Style.appearance.rounding.full

          IColouredIcon {
            anchors.centerIn: parent
            implicitSize: Math.round(Style.notifications.badge * 0.6)
            source: Quickshell.iconPath(root.appIcon)
            colour: root.urgency === NotificationUrgency.Critical ? ThemeService.palette.mOnError : root.urgency === NotificationUrgency.Low ? ThemeService.palette.mOnSurface : ThemeService.palette.mOnSecondary

            layer.enabled: root.appIcon.endsWith("symbolic")
          }
        }
      }
    }

    ColumnLayout {
      id: column

      Layout.topMargin: -Style.appearance.padding.small
      Layout.bottomMargin: -Style.appearance.padding.small / 2
      Layout.fillWidth: true
      spacing: 0

      RowLayout {
        id: header

        Layout.bottomMargin: root.expanded ? Math.round(Style.appearance.spacing.small / 2) : 0
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
          text: root.notifs.find(n => !n.closed)?.timeStr ?? ""
          color: ThemeService.palette.mOutline
          font.pointSize: Style.appearance.font.size.small
        }

        Rectangle {
          implicitWidth: expandBtn.implicitWidth + Style.appearance.padding.smaller * 2
          implicitHeight: groupCount.implicitHeight + Style.appearance.padding.small

          color: root.urgency === NotificationUrgency.Critical ? ThemeService.palette.mError : ThemeService.palette.mSurfaceContainerHigh

          radius: Style.appearance.rounding.full

          IStateLayer {
            color: root.urgency === NotificationUrgency.Critical ? ThemeService.palette.mOnError : ThemeService.palette.mOnSurface

            function onClicked(): void {
              root.toggleExpand(!root.expanded);
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
              text: root.notifCount
              color: root.urgency === NotificationUrgency.Critical ? ThemeService.palette.mOnError : ThemeService.palette.mOnSurface
              font.pointSize: Style.appearance.font.size.small
            }

            IIcon {
              Layout.rightMargin: -Style.appearance.padding.small / 2
              icon: "expand_more"
              color: root.urgency === NotificationUrgency.Critical ? ThemeService.palette.mOnError : ThemeService.palette.mOnSurface
              rotation: root.expanded ? 180 : 0
              Layout.topMargin: root.expanded ? -Math.floor(Style.appearance.padding.smaller / 2) : 0

              Behavior on rotation {
                IAnim {
                  duration: Style.appearance.anim.durations.expressiveDefaultSpatial
                  easing.bezierCurve: Style.appearance.anim.curves.expressiveDefaultSpatial
                }
              }

              Behavior on Layout.topMargin {
                IAnim {
                  duration: Style.appearance.anim.durations.expressiveDefaultSpatial
                  easing.bezierCurve: Style.appearance.anim.curves.expressiveDefaultSpatial
                }
              }
            }
          }
        }

        Behavior on Layout.bottomMargin {
          IAnim {}
        }
      }

      NotificationGroupList {
        id: notifList

        props: root.props
        notifs: root.notifs
        expanded: root.expanded
        container: root.container
        onRequestToggleExpand: expand => root.toggleExpand(expand)
      }
    }
  }
}
