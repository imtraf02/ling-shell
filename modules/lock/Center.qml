pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.widgets
import qs.services
import qs.utils

ColumnLayout {
  id: root

  required property var lock
  readonly property list<string> timeComponents: TimeService.format("hh:mm:A").split(":")
  readonly property real centerScale: Math.min(1, (lock.screen?.height ?? 1440) / 1440)
  readonly property int centerWidth: Style.lock.centerWidth * centerScale

  Layout.preferredWidth: centerWidth
  Layout.fillWidth: false
  Layout.fillHeight: true

  spacing: Style.appearance.spacing.large * 2

  RowLayout {
    Layout.alignment: Qt.AlignHCenter
    spacing: Style.appearance.spacing.small

    IText {
      Layout.alignment: Qt.AlignVCenter
      text: root.timeComponents[0]
      color: ThemeService.palette.mSecondary
      font.pointSize: Math.floor(Style.appearance.font.size.extraLarge * 3 * root.centerScale)
      font.family: Settings.appearance.font.clock
      font.bold: true
    }

    IText {
      Layout.alignment: Qt.AlignVCenter
      text: ":"
      color: ThemeService.palette.mPrimary
      font.pointSize: Math.floor(Style.appearance.font.size.extraLarge * 3 * root.centerScale)
      font.family: Settings.appearance.font.clock
      font.bold: true
    }

    IText {
      Layout.alignment: Qt.AlignVCenter
      text: root.timeComponents[1]
      color: ThemeService.palette.mSecondary
      font.pointSize: Math.floor(Style.appearance.font.size.extraLarge * 3 * root.centerScale)
      font.family: Settings.appearance.font.clock
      font.bold: true
    }

    Loader {
      Layout.leftMargin: Style.appearance.spacing.small
      Layout.alignment: Qt.AlignVCenter
      asynchronous: true
      active: true
      visible: active

      sourceComponent: IText {
        text: root.timeComponents[2] ?? ""
        color: ThemeService.palette.mPrimary
        font.pointSize: Math.floor(Style.appearance.font.size.extraLarge * 2 * root.centerScale)
        font.family: Settings.appearance.font.clock
        font.bold: true
      }
    }
  }

  IText {
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: -Style.appearance.padding.large * 2
    text: TimeService.format("dddd, d MMMM yyyy")
    color: ThemeService.palette.mTertiary
    font.pointSize: Math.floor(Style.appearance.font.size.extraLarge * root.centerScale)
    font.family: Settings.appearance.font.mono
    font.bold: true
  }

  IImageCircled {
    Layout.topMargin: Style.appearance.spacing.large * 2
    Layout.alignment: Qt.AlignHCenter
    implicitWidth: root.centerWidth / 2
    implicitHeight: root.centerWidth / 2
    imagePath: FileUtils.trimFileProtocol(Settings.general.avatarImage)
    fallbackIcon: "person"
    borderColor: ThemeService.palette.mPrimary
    borderWidth: 1
  }

  Rectangle {
    Layout.alignment: Qt.AlignHCenter
    implicitWidth: root.centerWidth * 0.8
    implicitHeight: input.implicitHeight + Style.appearance.padding.small * 2
    color: ThemeService.palette.mSurfaceContainer
    radius: Style.appearance.rounding.full
    focus: true

    onActiveFocusChanged: {
      if (!activeFocus)
        forceActiveFocus();
    }

    Keys.onPressed: event => {
      if (root.lock.unlocking)
        return;
      if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
        inputField.placeholder.animate = false;
      }
      root.lock.pam.handleKey(event);
    }

    IStateLayer {
      hoverEnabled: false
      cursorShape: Qt.IBeamCursor
      function onClicked() {
        parent.forceActiveFocus();
      }
    }

    RowLayout {
      id: input
      anchors.fill: parent
      anchors.margins: Style.appearance.padding.small
      spacing: Style.appearance.spacing.normal

      Item {
        implicitWidth: implicitHeight
        implicitHeight: fprintIcon.implicitHeight + Style.appearance.padding.small * 2

        IIcon {
          id: fprintIcon
          anchors.centerIn: parent
          icon: {
            if (root.lock.pam.fprint.tries >= Settings.lock.maxFprintTries)
              return "fingerprint_off";
            if (root.lock.pam.fprint.active)
              return "fingerprint";
            return "lock";
          }
          color: root.lock.pam.fprint.tries >= Settings.lock.maxFprintTries ? ThemeService.palette.mError : ThemeService.palette.mOnSurface

          opacity: root.lock.pam.passwd.active ? 0 : 1

          Behavior on opacity {
            IAnim {}
          }
        }

        IBusyIndicator {
          anchors.fill: parent
          running: root.lock.pam.passwd.active
          color: ThemeService.palette.mPrimary
          Layout.alignment: Qt.AlignHCenter
        }
      }

      InputField {
        id: inputField
        pam: root.lock.pam
      }

      Rectangle {
        implicitWidth: implicitHeight
        implicitHeight: enterIcon.implicitHeight + Style.appearance.padding.small * 2
        color: root.lock.pam.buffer ? ThemeService.palette.mPrimary : Qt.alpha(ThemeService.palette.mSurfaceContainerHigh, 1)
        radius: Style.appearance.rounding.full

        IStateLayer {
          color: root.lock.pam.buffer ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface
          function onClicked() {
            root.lock.pam.passwd.start();
          }
        }

        IIcon {
          id: enterIcon
          anchors.centerIn: parent
          icon: "arrow_forward"
          color: root.lock.pam.buffer ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface
          font.weight: 500
        }
      }
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.topMargin: -Style.appearance.spacing.large
    implicitHeight: Math.max(message.implicitHeight, stateMessage.implicitHeight)

    Behavior on implicitHeight {
      IAnim {}
    }

    IText {
      id: stateMessage

      readonly property string msg: {
        if (LockKeysService.capsLockOn && LockKeysService.numLockOn)
          return "Caps lock and Num lock are ON.";
        if (LockKeysService.capsLockOn)
          return "Caps lock is ON.";
        if (LockKeysService.numLockOn)
          return "Num lock is ON.";
        return "";
      }

      property bool shouldBeVisible

      onMsgChanged: {
        if (msg) {
          if (opacity > 0) {
            animate = true;
            text = msg;
            animate = false;
          } else {
            text = msg;
          }
          shouldBeVisible = true;
        } else {
          shouldBeVisible = false;
        }
      }

      anchors.left: parent.left
      anchors.right: parent.right
      scale: shouldBeVisible && !message.msg ? 1 : 0.7
      opacity: shouldBeVisible && !message.msg ? 1 : 0
      color: ThemeService.palette.mOnSurfaceVariant
      font.family: Settings.appearance.font.mono
      horizontalAlignment: Qt.AlignHCenter
      wrapMode: Text.WrapAtWordBoundaryOrAnywhere
      lineHeight: 1.2

      Behavior on scale {
        IAnim {}
      }
      Behavior on opacity {
        IAnim {}
      }
    }

    IText {
      id: message

      readonly property Pam pam: root.lock.pam
      readonly property string msg: {
        if (pam.fprintState === "error")
          return "FP ERROR: " + pam.fprint.message;
        if (pam.state === "error")
          return "PW ERROR: " + pam.passwd.message;
        if (pam.lockMessage)
          return pam.lockMessage;
        if (pam.state === "max" && pam.fprintState === "max")
          return "Maximum password and fingerprint attempts reached.";
        if (pam.state === "max") {
          if (pam.fprint.available)
            return "Maximum password attempts reached. Please use fingerprint.";
          return "Maximum password attempts reached.";
        }
        if (pam.fprintState === "max")
          return "Maximum fingerprint attempts reached. Please use password.";
        if (pam.state === "fail") {
          if (pam.fprint.available)
            return "Incorrect password. Please try again or use fingerprint.";
          return "Incorrect password. Please try again.";
        }
        if (pam.fprintState === "fail")
          return "Fingerprint not recognized (" + pam.fprint.tries + "/" + Settings.lock.maxFprintTries + "). Please try again or use password.";
        return "";
      }

      anchors.left: parent.left
      anchors.right: parent.right
      scale: 0.7
      opacity: 0
      color: ThemeService.palette.mError
      font.pointSize: Style.appearance.font.size.small
      font.family: Settings.appearance.font.mono
      horizontalAlignment: Qt.AlignHCenter
      wrapMode: Text.WrapAtWordBoundaryOrAnywhere

      onMsgChanged: {
        if (msg) {
          if (opacity > 0) {
            animate = true;
            text = msg;
            animate = false;
            exitAnim.stop();
            if (scale < 1)
              appearAnim.restart();
            else
              flashAnim.restart();
          } else {
            text = msg;
            exitAnim.stop();
            appearAnim.restart();
          }
        } else {
          appearAnim.stop();
          flashAnim.stop();
          exitAnim.start();
        }
      }

      Connections {
        target: root.lock.pam
        function onFlashMsg() {
          exitAnim.stop();
          if (message.scale < 1)
            appearAnim.restart();
          else
            flashAnim.restart();
        }
      }

      IAnim {
        id: appearAnim
        target: message
        properties: "scale,opacity"
        to: 1
        onFinished: flashAnim.restart()
      }

      SequentialAnimation {
        id: flashAnim
        loops: 2
        FlashAnim {
          to: 0.3
        }
        FlashAnim {
          to: 1
        }
      }

      ParallelAnimation {
        id: exitAnim
        IAnim {
          target: message
          property: "scale"
          to: 0.7
          duration: Style.appearance.anim.durations.large
        }
        IAnim {
          target: message
          property: "opacity"
          to: 0
          duration: Style.appearance.anim.durations.large
        }
      }
    }
  }

  component FlashAnim: NumberAnimation {
    target: message
    property: "opacity"
    duration: Style.appearance.anim.durations.small
    easing.type: Easing.Linear
  }
}
