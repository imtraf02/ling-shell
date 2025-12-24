pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.utils
import qs.services
import qs.widgets

Rectangle {
  id: root

  readonly property int padding: Config.appearance.padding.normal
  readonly property int spacing: Config.appearance.spacing.small
  required property NotificationService.Notif modelData
  readonly property bool hasImage: modelData.image.length > 0
  readonly property bool hasAppIcon: modelData.appIcon.length > 0
  readonly property int nonAnimHeight: Math.max(summary.implicitHeight + (root.expanded ? appName.height + body.height + actions.height + actions.anchors.topMargin : bodyPreview.height), Config.notifications.sizes.image) + inner.anchors.margins * 2
  property bool expanded

  color: root.modelData.urgency === NotificationUrgency.Critical ? ThemeService.palette.mSecondary : ThemeService.palette.mSurfaceContainer
  radius: Config.appearance.rounding.normal
  implicitWidth: Config.notifications.sizes.width
  implicitHeight: inner.implicitHeight

  x: Config.notifications.sizes.width
  Component.onCompleted: {
    x = 0;
    modelData.lock(this);
  }
  Component.onDestruction: modelData.unlock(this)

  Behavior on x {
    IAnim {
      easing.bezierCurve: Config.appearance.anim.curves.emphasizedDecel
    }
  }

  MouseArea {
    property int startY

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.expanded && body.hoveredLink ? Qt.PointingHandCursor : pressed ? Qt.ClosedHandCursor : undefined
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    preventStealing: true

    onEntered: root.modelData.timer.stop()
    onExited: {
      if (!pressed)
        root.modelData.timer.start();
    }

    drag.target: parent
    drag.axis: Drag.XAxis

    onPressed: event => {
      root.modelData.timer.stop();
      startY = event.y;
      if (event.button === Qt.MiddleButton)
        root.modelData.close();
    }
    onReleased: event => {
      if (!containsMouse)
        root.modelData.timer.start();

      if (Math.abs(root.x) < Config.notifications.sizes.width * Config.notifications.clearThreshold)
        root.x = 0;
      else
        root.modelData.popup = false;
    }
    onPositionChanged: event => {
      if (pressed) {
        const diffY = event.y - startY;
        if (Math.abs(diffY) > Config.notifications.expandThreshold)
          root.expanded = diffY > 0;
      }
    }
    onClicked: event => {
      if (!Config.notifications.actionOnClick || event.button !== Qt.LeftButton)
        return;

      const actions = root.modelData.actions;
      if (actions?.length === 1)
        actions[0].invoke();
    }

    Item {
      id: inner

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: root.padding

      implicitHeight: root.nonAnimHeight

      Behavior on implicitHeight {
        IAnim {
          duration: Config.appearance.anim.durations.expressiveDefaultSpatial
          easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
        }
      }

      Loader {
        id: image

        active: root.hasImage
        asynchronous: true

        anchors.left: parent.left
        anchors.top: parent.top
        width: Config.notifications.sizes.image
        height: Config.notifications.sizes.image
        visible: root.hasImage || root.hasAppIcon

        sourceComponent: ClippingRectangle {
          radius: Config.appearance.rounding.full
          implicitWidth: Config.notifications.sizes.image
          implicitHeight: Config.notifications.sizes.image

          Image {
            anchors.fill: parent
            source: Qt.resolvedUrl(root.modelData.image)
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: true
          }
        }
      }

      Loader {
        id: appIcon

        active: root.hasAppIcon || !root.hasImage
        asynchronous: true

        anchors.horizontalCenter: root.hasImage ? undefined : image.horizontalCenter
        anchors.verticalCenter: root.hasImage ? undefined : image.verticalCenter
        anchors.right: root.hasImage ? image.right : undefined
        anchors.bottom: root.hasImage ? image.bottom : undefined

        sourceComponent: Rectangle {
          radius: Config.appearance.rounding.full
          color: root.modelData.urgency === NotificationUrgency.Critical ? ThemeService.palette.mError : root.modelData.urgency === NotificationUrgency.Low ? ThemeService.palette.mSurfaceContainerHighest : ThemeService.palette.mSecondary
          implicitWidth: root.hasImage ? Config.notifications.sizes.badge : Config.notifications.sizes.image
          implicitHeight: root.hasImage ? Config.notifications.sizes.badge : Config.notifications.sizes.image

          Loader {
            id: icon

            active: root.hasAppIcon
            asynchronous: true

            anchors.centerIn: parent

            width: Math.round(parent.width * 0.6)
            height: Math.round(parent.width * 0.6)

            sourceComponent: IColouredIcon {
              anchors.fill: parent
              source: Quickshell.iconPath(root.modelData.appIcon)
              colour: root.modelData.urgency === NotificationUrgency.Critical ? ThemeService.palette.mOnError : root.modelData.urgency === NotificationUrgency.Low ? ThemeService.palette.mOnSurface : ThemeService.palette.mOnSecondary
              layer.enabled: root.modelData.appIcon.endsWith("symbolic")
            }
          }

          Loader {
            active: !root.hasAppIcon
            asynchronous: true
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -Config.appearance.font.size.large * 0.02
            anchors.verticalCenterOffset: Config.appearance.font.size.large * 0.02

            sourceComponent: IIcon {
              icon: Icons.getNotifIcon(root.modelData.summary, root.modelData.urgency)

              color: root.modelData.urgency === NotificationUrgency.Critical ? ThemeService.palette.mOnError : root.modelData.urgency === NotificationUrgency.Low ? ThemeService.palette.mOnSurface : ThemeService.palette.mOnSecondary
              font.pointSize: Config.appearance.font.size.large
            }
          }
        }
      }

      IText {
        id: appName

        anchors.top: parent.top
        anchors.left: image.right
        anchors.leftMargin: root.spacing

        animate: true
        text: appNameMetrics.elidedText
        maximumLineCount: 1
        color: ThemeService.palette.mOnSurfaceVariant
        font.pointSize: Config.appearance.font.size.small

        opacity: root.expanded ? 1 : 0

        Behavior on opacity {
          IAnim {}
        }
      }

      TextMetrics {
        id: appNameMetrics

        text: root.modelData.appName
        font.family: appName.font.family
        font.pointSize: appName.font.pointSize
        elide: Text.ElideRight
        elideWidth: expandBtn.x - time.width - timeSep.width - summary.x - Config.appearance.spacing.small * 3
      }

      IText {
        id: summary

        anchors.top: parent.top
        anchors.left: image.right
        anchors.leftMargin: root.spacing

        animate: true
        text: summaryMetrics.elidedText
        maximumLineCount: 1
        height: implicitHeight

        states: State {
          name: "expanded"
          when: root.expanded

          PropertyChanges {
            summary.maximumLineCount: undefined
          }

          AnchorChanges {
            target: summary
            anchors.top: appName.bottom
          }
        }

        transitions: Transition {
          PropertyAction {
            target: summary
            property: "maximumLineCount"
          }
          AnchorAnimation {
            duration: Config.appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Config.appearance.anim.curves.standard
          }
        }

        Behavior on height {
          IAnim {}
        }
      }

      TextMetrics {
        id: summaryMetrics

        text: root.modelData.summary
        font.family: summary.font.family
        font.pointSize: summary.font.pointSize
        elide: Text.ElideRight
        elideWidth: expandBtn.x - time.width - timeSep.width - summary.x - root.spacing * 3
      }

      IText {
        id: timeSep

        anchors.top: parent.top
        anchors.left: summary.right
        anchors.leftMargin: Config.appearance.spacing.small

        text: "•"
        color: ThemeService.palette.mOnSurfaceVariant
        font.pointSize: Config.appearance.font.size.small

        states: State {
          name: "expanded"
          when: root.expanded

          AnchorChanges {
            target: timeSep
            anchors.left: appName.right
          }
        }

        transitions: Transition {
          AnchorAnimation {
            duration: Config.appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Config.appearance.anim.curves.standard
          }
        }
      }

      IText {
        id: time

        anchors.top: parent.top
        anchors.left: timeSep.right
        anchors.leftMargin: root.padding

        animate: true
        horizontalAlignment: Text.AlignLeft
        text: root.modelData.timeStr
        color: ThemeService.palette.mOnSurfaceVariant
        font.pointSize: Config.appearance.font.size.small
      }

      Item {
        id: expandBtn

        anchors.right: parent.right
        anchors.top: parent.top

        implicitWidth: expandIcon.height
        implicitHeight: expandIcon.height

        IStateLayer {
          radius: Config.appearance.rounding.full
          color: root.modelData.urgency === NotificationUrgency.Critical ? ThemeService.palette.mOnSecondary : ThemeService.palette.mOnSurface

          function onClicked() {
            root.expanded = !root.expanded;
          }
        }

        IIcon {
          id: expandIcon

          anchors.centerIn: parent

          animate: true
          icon: root.expanded ? "expand_less" : "expand_more"
          font.pointSize: Config.appearance.font.size.normal
        }
      }

      IText {
        id: bodyPreview

        anchors.left: summary.left
        anchors.right: expandBtn.left
        anchors.top: summary.bottom
        anchors.rightMargin: root.padding

        animate: true
        textFormat: Text.MarkdownText
        text: bodyPreviewMetrics.elidedText
        color: ThemeService.palette.mOnSurfaceVariant
        font.pointSize: Config.appearance.font.size.small

        opacity: root.expanded ? 0 : 1

        Behavior on opacity {
          IAnim {}
        }
      }

      TextMetrics {
        id: bodyPreviewMetrics

        text: root.modelData.body
        font.family: bodyPreview.font.family
        font.pointSize: bodyPreview.font.pointSize
        elide: Text.ElideRight
        elideWidth: bodyPreview.width
      }

      IText {
        id: body

        anchors.left: summary.left
        anchors.right: expandBtn.left
        anchors.top: summary.bottom
        anchors.rightMargin: root.padding

        animate: true
        textFormat: Text.MarkdownText
        text: root.modelData.body
        color: ThemeService.palette.mOnSurfaceVariant
        font.pointSize: Config.appearance.font.size.small
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        height: text ? implicitHeight : 0

        onLinkActivated: link => {
          if (!root.expanded)
            return;

          Quickshell.execDetached(["app2unit", "-O", "--", link]);
          root.modelData.popup = false;
        }

        opacity: root.expanded ? 1 : 0

        Behavior on opacity {
          IAnim {}
        }
      }

      RowLayout {
        id: actions

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: body.bottom
        anchors.topMargin: root.padding

        spacing: root.spacing

        opacity: root.expanded ? 1 : 0

        Behavior on opacity {
          IAnim {}
        }

        Action {
          modelData: QtObject {
            readonly property string text: qsTr("Close")
            function invoke(): void {
              root.modelData.close();
            }
          }
        }

        Repeater {
          model: root.modelData.actions

          delegate: Component {
            Action {}
          }
        }
      }
    }
  }

  component Action: Rectangle {
    id: action

    required property var modelData

    radius: Config.appearance.rounding.full
    color: root.modelData.urgency === NotificationUrgency.Critical ? ThemeService.palette.mSecondary : ThemeService.palette.mSurfaceContainerHigh

    Layout.preferredWidth: actionText.width + root.padding * 2
    Layout.preferredHeight: actionText.height + root.padding * 2
    implicitWidth: actionText.width + root.padding * 2
    implicitHeight: actionText.height + root.padding * 2

    IStateLayer {
      radius: Config.appearance.rounding.full
      color: root.modelData.urgency === NotificationUrgency.Critical ? ThemeService.palette.mOnSecondary : ThemeService.palette.mOnSurface

      function onClicked(): void {
        action.modelData.invoke();
      }
    }

    IText {
      id: actionText

      anchors.centerIn: parent
      text: actionTextMetrics.elidedText
      color: root.modelData.urgency === NotificationUrgency.Critical ? ThemeService.palette.mOnSecondary : ThemeService.palette.mOnSurfaceVariant
      font.pointSize: Config.appearance.font.size.small
    }

    TextMetrics {
      id: actionTextMetrics

      text: action.modelData.text
      font.family: actionText.font.family
      font.pointSize: actionText.font.pointSize
      elide: Text.ElideRight
      elideWidth: {
        const numActions = root.modelData.actions.length + 1;
        return (inner.width - actions.spacing * (numActions - 1)) / numActions - root.padding * 2;
      }
    }
  }
}
