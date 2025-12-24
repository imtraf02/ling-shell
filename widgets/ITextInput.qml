import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.commons
import qs.services

ColumnLayout {
  id: root

  property string label: ""
  property string description: ""
  property string inputIconName: ""
  property bool readOnly: false
  property bool enabled: true
  property color labelColor: ThemeService.palette.mOnSurface
  property color descriptionColor: ThemeService.palette.mOnSurfaceVariant
  property real fontSize: Config.appearance.font.size.small
  property int fontWeight: Settings.appearance.font.weight

  property alias text: input.text
  property alias placeholderText: input.placeholderText
  property alias inputMethodHints: input.inputMethodHints
  property alias inputItem: input

  signal editingFinished
  signal accepted

  spacing: Config.appearance.spacing.small

  ILabel {
    label: root.label
    description: root.description
    labelColor: root.labelColor
    descriptionColor: root.descriptionColor
    visible: root.label !== "" || root.description !== ""
    Layout.fillWidth: true
  }

  Control {
    id: frameControl

    Layout.fillWidth: true
    Layout.minimumWidth: 80
    implicitHeight: Config.appearance.widget.size * 1.1

    focusPolicy: Qt.StrongFocus
    hoverEnabled: true

    background: Rectangle {
      id: frame

      radius: Settings.appearance.cornerRadius
      color: ThemeService.palette.mSurface
      border.color: input.activeFocus ? Qt.alpha(ThemeService.palette.mSecondary, 0.6) : Qt.alpha(ThemeService.palette.mOutline, 0.4)
      border.width: 2

      Behavior on border.color {
        ICAnim {}
      }
    }

    contentItem: Item {
      id: rootContent
      anchors.fill: parent

      MouseArea {
        id: backgroundCapture
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        preventStealing: true
        propagateComposedEvents: false

        onPressed: mouse => {
          mouse.accepted = true;
          input.forceActiveFocus();
          var inputPos = mapToItem(inputContainer, mouse.x, mouse.y);
          if (inputPos.x >= 0 && inputPos.x <= inputContainer.width) {
            var textPos = inputPos.x - Config.appearance.padding.larger;
            if (textPos >= 0 && textPos <= input.width) {
              input.cursorPosition = input.positionAt(textPos, input.height / 2);
            }
          }
        }

        onReleased: mouse => mouse.accepted = true

        onDoubleClicked: mouse => {
          mouse.accepted = true;
          input.selectAll();
        }

        onPositionChanged: mouse => mouse.accepted = true

        onWheel: wheel => wheel.accepted = true
      }

      Item {
        id: inputContainer
        anchors.fill: parent
        anchors.leftMargin: Config.appearance.padding.larger
        clip: true
        z: 1

        RowLayout {
          anchors.fill: parent
          spacing: 0

          IIcon {
            id: inputIcon
            icon: root.inputIconName

            visible: root.inputIconName !== ""
            enabled: false

            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: visible ? Config.appearance.spacing.small : 0
          }

          TextField {
            id: input

            Layout.fillWidth: true
            Layout.fillHeight: true

            verticalAlignment: TextInput.AlignVCenter
            font.family: Config.appearance.font.family.sans

            echoMode: TextInput.Normal
            readOnly: root.readOnly
            enabled: root.enabled
            color: ThemeService.palette.mOnSurface
            placeholderTextColor: ThemeService.palette.mOutline

            selectByMouse: true

            topPadding: 0
            bottomPadding: 0
            leftPadding: 0
            rightPadding: 0

            background: null

            font.pointSize: root.fontSize
            font.weight: root.fontWeight

            onEditingFinished: root.editingFinished()
            onAccepted: root.accepted()

            MouseArea {
              id: textFieldMouse
              anchors.fill: parent
              acceptedButtons: Qt.AllButtons
              preventStealing: true
              propagateComposedEvents: false
              cursorShape: Qt.IBeamCursor

              property int selectionStart: 0

              onPressed: mouse => {
                mouse.accepted = true;
                input.forceActiveFocus();
                var pos = input.positionAt(mouse.x, mouse.y);
                input.cursorPosition = pos;
                selectionStart = pos;
              }

              onPositionChanged: mouse => {
                if (mouse.buttons & Qt.LeftButton) {
                  mouse.accepted = true;
                  var pos = input.positionAt(mouse.x, mouse.y);
                  input.select(selectionStart, pos);
                }
              }

              onDoubleClicked: mouse => {
                mouse.accepted = true;
                input.selectAll();
              }

              onReleased: mouse => mouse.accepted = true

              onWheel: wheel => wheel.accepted = true
            }
          }

          IIconButton {
            id: clearButton
            icon: "close"

            Layout.alignment: Qt.AlignVCenter

            border.width: 0

            colorBg: "transparent"
            colorBgHover: "transparent"
            colorFg: ThemeService.palette.mOnSurface
            colorFgHover: ThemeService.palette.mError

            visible: input.text.length > 0 && !root.readOnly
            enabled: input.text.length > 0 && !root.readOnly

            onClicked: {
              input.clear();
              input.forceActiveFocus();
            }
          }
        }
      }
    }
  }
}
