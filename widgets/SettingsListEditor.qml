import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

ColumnLayout {
  id: root

  property string label: ""
  property string description: ""
  property string placeholder: "Add an item"
  property var values: []

  signal updated(var values)

  Layout.fillWidth: true
  spacing: Style.spacing.small

  ILabel {
    label: root.label
    description: root.description
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.spacing.small

    ITextInput {
      id: input
      Layout.fillWidth: true
      placeholderText: root.placeholder
      onAccepted: addValue()
    }
    IIconButton {
      icon: "add"
      onClicked: addValue()
    }
  }

  Flow {
    Layout.fillWidth: true
    spacing: Style.spacing.small
    visible: root.values && root.values.length > 0

    Repeater {
      model: root.values || []
      delegate: Rectangle {
        required property string modelData
        width: chipRow.implicitWidth + Style.padding.small * 2
        height: chipRow.implicitHeight + Style.padding.small * 2
        radius: Style.rounding.full
        color: ThemeService.palette.mSurfaceVariant

        RowLayout {
          id: chipRow
          anchors.centerIn: parent
          spacing: Style.spacing.small
          IText {
            text: modelData
            font.pointSize: Style.font.size.small
            elide: Text.ElideRight
            Layout.maximumWidth: 260
          }
          IIconButton {
            icon: "close"
            size: Math.round(Style.widget.size * 0.7)
            onClicked: removeValue(modelData)
          }
        }
      }
    }
  }

  IText {
    visible: !root.values || root.values.length === 0
    text: "No entries."
    color: ThemeService.palette.mOnSurfaceVariant
    font.pointSize: Style.font.size.small
  }

  function addValue() {
    const value = input.text.trim();
    if (!value || (root.values || []).includes(value))
      return;
    root.updated((root.values || []).concat([value]));
    input.text = "";
  }

  function removeValue(value) {
    root.updated((root.values || []).filter(item => item !== value));
  }
}
