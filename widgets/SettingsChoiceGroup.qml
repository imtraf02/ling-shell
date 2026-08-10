pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

ColumnLayout {
  id: root

  property string label: ""
  property string description: ""
  property var model: []
  property string currentKey: ""
  property real buttonHeight: 40

  signal selected(string key)

  Layout.fillWidth: true
  spacing: 6

  ILabel {
    label: root.label
    description: root.description
  }

  IButtonGroup {
    Layout.fillWidth: true
    Layout.preferredHeight: root.buttonHeight + padding * 2
    segmented: true
    uniformCellSizes: true

    Repeater {
      model: root.model
      delegate: IGroupButton {
        required property var modelData
        text: modelData.name || ""
        icon: modelData.icon || ""
        selected: root.currentKey === modelData.key
        bounce: false
        baseHeight: root.buttonHeight
        onClicked: root.selected(String(modelData.key))
      }
    }
  }
}
