import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.commons
import qs.services

RowLayout {
  id: root

  property real value: 0.0
  property real from: 0.0
  property real to: 100.0
  property real stepSize: 1.0
  property string suffix: ""
  property string prefix: ""
  property string label: ""
  property string description: ""
  property bool enabled: true
  property bool hovering: false
  property int baseSize: Config.appearance.widget.size

  property alias minimum: root.from
  property alias maximum: root.to

  signal entered
  signal exited

  Layout.fillWidth: true

  ILabel {
    label: root.label
    description: root.description
  }

  Rectangle {
    id: spinBoxContainer
    implicitWidth: 120
    implicitHeight: root.baseSize - 4
    radius: Settings.appearance.cornerRadius
    color: ThemeService.palette.mSurfaceVariant
    border.color: (root.hovering || decreaseArea.containsMouse || increaseArea.containsMouse) ? ThemeService.palette.mPrimary : ThemeService.palette.mOutline
    border.width: 1

    Behavior on border.color {
      ICAnim {}
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.NoButton
      hoverEnabled: true

      onEntered: {
        root.hovering = true;
        root.entered();
      }
      onExited: {
        root.hovering = false;
        root.exited();
      }
      onWheel: wheel => {
        if (wheel.angleDelta.y > 0)
          root.value = Math.min(root.to, root.value + root.stepSize);
        else if (wheel.angleDelta.y < 0)
          root.value = Math.max(root.from, root.value - root.stepSize);
      }
    }

    Item {
      id: decreaseButton
      width: height
      height: parent.height
      anchors.left: parent.left
      opacity: root.enabled && root.value > root.from ? 1.0 : 0.3

      Rectangle {
        anchors.fill: parent
        radius: Settings.appearance.cornerRadius
        color: decreaseArea.containsMouse ? ThemeService.palette.mPrimary : "transparent"
        Behavior on color {
          ICAnim {}
        }
      }

      IIcon {
        anchors.centerIn: parent
        icon: "arrow_left"
        color: decreaseArea.containsMouse ? ThemeService.palette.mOnPrimary : ThemeService.palette.mPrimary
      }

      MouseArea {
        id: decreaseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: root.enabled && root.value > root.from
        onClicked: root.value = Math.max(root.from, root.value - root.stepSize)
      }
    }

    Item {
      id: increaseButton
      width: height
      height: parent.height
      anchors.right: parent.right
      opacity: root.enabled && root.value < root.to ? 1.0 : 0.3

      Rectangle {
        anchors.fill: parent
        radius: Settings.appearance.cornerRadius
        color: increaseArea.containsMouse ? ThemeService.palette.mPrimary : "transparent"
        Behavior on color {
          ICAnim {}
        }
      }

      IIcon {
        anchors.centerIn: parent
        icon: "arrow_right"
        color: increaseArea.containsMouse ? ThemeService.palette.mOnPrimary : ThemeService.palette.mPrimary
      }

      MouseArea {
        id: increaseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: root.enabled && root.value < root.to
        onClicked: root.value = Math.min(root.to, root.value + root.stepSize)
      }
    }

    Rectangle {
      id: valueContainer
      anchors.left: decreaseButton.right
      anchors.right: increaseButton.left
      anchors.verticalCenter: parent.verticalCenter
      anchors.margins: 4
      height: parent.height
      color: "transparent"

      RowLayout {
        anchors.centerIn: parent
        spacing: 0

        IText {
          text: root.prefix
          family: Settings.appearance.font.mono
          pointSize: Config.appearance.font.size.normal
          color: ThemeService.palette.mOnSurface
          visible: root.prefix !== ""
        }

        TextInput {
          id: valueInput
          text: valueInput.focus ? valueInput.text : Number(root.value.toFixed(2)).toString()

          font.family: Settings.appearance.font.mono
          font.pointSize: Config.appearance.font.size.normal
          color: ThemeService.palette.mOnSurface
          selectByMouse: true
          enabled: root.enabled

          validator: DoubleValidator {
            bottom: root.from
            top: root.to
            decimals: 6
            notation: DoubleValidator.StandardNotation
          }

          Keys.onReturnPressed: {
            applyValue();
            focus = false;
          }
          Keys.onEscapePressed: {
            text = root.value.toString();
            focus = false;
          }
          onFocusChanged: {
            if (focus)
              selectAll();
            else
              applyValue();
          }

          function snapToStep(v) {
            let base = root.from;
            let step = root.stepSize;
            let snapped = base + Math.round((v - base) / step) * step;
            return Number(snapped.toFixed(6));
          }

          function applyValue() {
            let v = parseFloat(text);
            if (isNaN(v))
              return;
            v = Math.max(root.from, Math.min(root.to, v));
            v = snapToStep(v);

            root.value = v;
          }
        }

        IText {
          text: root.suffix
          family: Settings.appearance.font.mono
          pointSize: Config.appearance.font.size.normal
          color: ThemeService.palette.mOnSurface
          visible: root.suffix !== ""
        }
      }
    }
  }
}
