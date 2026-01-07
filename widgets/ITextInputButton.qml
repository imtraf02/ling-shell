import QtQuick
import QtQuick.Layouts
import qs.commons

ColumnLayout {
  id: root
  Layout.fillWidth: true

  property alias text: input.text
  property alias placeholderText: input.placeholderText
  property string label: ""
  property string description: ""
  property string inputIconName: ""
  property alias buttonIcon: button.icon
  property alias buttonEnabled: button.enabled
  property real maximumWidth: 0

  signal buttonClicked
  signal inputTextChanged(string text)
  signal inputEditingFinished

  spacing: Style.appearance.spacing.small

  ILabel {
    label: root.label
    description: root.description
    visible: root.label !== "" || root.description !== ""
    Layout.fillWidth: true
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.appearance.spacing.small

    ITextInput {
      id: input
      inputIconName: root.inputIconName
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      onTextChanged: root.inputTextChanged(text)
      onEditingFinished: root.inputEditingFinished()
    }

    IIconButton {
      id: button
      size: Style.appearance.widget.size
      onClicked: root.buttonClicked()
    }
  }
}
