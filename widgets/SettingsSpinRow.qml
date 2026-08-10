import QtQuick
import QtQuick.Layouts

Item {
  id: root

  property string label: ""
  property string description: ""
  property real value: 0
  property real from: 0
  property real to: 100
  property real stepSize: 1
  property string suffix: ""
  property bool enabled: true

  signal changed(real value)

  Layout.fillWidth: true
  implicitHeight: spin.implicitHeight

  ISpinBox {
    id: spin
    anchors.fill: parent
    label: root.label
    description: root.description
    value: root.value
    from: root.from
    to: root.to
    stepSize: root.stepSize
    suffix: root.suffix
    enabled: root.enabled
    onValueChanged: {
      if (value !== root.value)
        root.changed(value);
    }
  }
}
