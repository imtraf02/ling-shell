pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

Item {
  id: root

  required property Pam pam
  readonly property alias placeholder: placeholder
  property string buffer

  Layout.fillWidth: true
  Layout.fillHeight: true

  clip: true

  Connections {
    target: root.pam

    function onBufferChanged(): void {
      if (root.pam.buffer.length > root.buffer.length) {
        charList.bindImWidth();
      } else if (root.pam.buffer.length === 0) {
        charList.implicitWidth = charList.implicitWidth;
        placeholder.animate = true;
      }

      root.buffer = root.pam.buffer;
    }
  }

  IText {
    id: placeholder

    anchors.centerIn: parent

    text: {
      if (root.pam.passwd.active)
        return qsTr("Loading...");
      if (root.pam.state === "max")
        return qsTr("You have reached the maximum number of tries");
      return qsTr("Enter your password");
    }

    color: root.pam.passwd.active ? ThemeService.palette.mSecondary : ThemeService.palette.mOutline
    font.pointSize: Config.appearance.font.size.normal
    font.family: Config.appearance.font.family.mono

    opacity: root.buffer ? 0 : 1

    Behavior on opacity {
      IAnim {}
    }
  }

  ListView {
    id: charList

    readonly property int fullWidth: count * (implicitHeight + spacing) - spacing

    function bindImWidth(): void {
      imWidthBehavior.enabled = false;
      implicitWidth = Qt.binding(() => fullWidth);
      imWidthBehavior.enabled = true;
    }

    anchors.centerIn: parent
    anchors.horizontalCenterOffset: implicitWidth > root.width ? -(implicitWidth - root.width) / 2 : 0

    implicitWidth: fullWidth
    implicitHeight: Config.appearance.font.size.normal

    orientation: Qt.Horizontal
    spacing: Config.appearance.spacing.small / 2
    interactive: false

    model: ScriptModel {
      values: root.buffer.split("")
    }

    delegate: Rectangle {
      id: ch

      implicitWidth: implicitHeight
      implicitHeight: charList.implicitHeight

      color: ThemeService.palette.mOnSurface
      radius: Config.appearance.rounding.small / 2

      opacity: 0
      scale: 0
      Component.onCompleted: {
        opacity = 1;
        scale = 1;
      }
      ListView.onRemove: removeAnim.start()

      SequentialAnimation {
        id: removeAnim

        PropertyAction {
          target: ch
          property: "ListView.delayRemove"
          value: true
        }
        ParallelAnimation {
          IAnim {
            target: ch
            property: "opacity"
            to: 0
          }
          IAnim {
            target: ch
            property: "scale"
            to: 0.5
          }
        }
        PropertyAction {
          target: ch
          property: "ListView.delayRemove"
          value: false
        }
      }

      Behavior on opacity {
        IAnim {}
      }

      Behavior on scale {
        IAnim {
          duration: Config.appearance.anim.durations.expressiveFastSpatial
          easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
        }
      }
    }

    Behavior on implicitWidth {
      id: imWidthBehavior

      IAnim {}
    }
  }
}
