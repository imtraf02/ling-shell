pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
  id: root
  property color fillColor: ThemeService.palette.mPrimary
  property color strokeColor: ThemeService.palette.mOnSurface
  property int strokeWidth: 0
  property var values: []

  // Minimum signal properties
  property bool showMinimumSignal: false
  property real minimumSignalValue: 0.05 // Default to 5% of height

  // Pre compute horizontal mirroring
  readonly property int valuesCount: values.length
  readonly property int totalBars: valuesCount * 2
  readonly property real barSlotSize: totalBars > 0 ? width / totalBars : 0

  Repeater {
    model: root.totalBars

    Rectangle {
      required property int index

      property int valueIndex: index < root.valuesCount ? root.valuesCount - 1 - index // Mirrored half
      : index - root.valuesCount // Normal half

      property real rawAmp: root.values[valueIndex]
      property real amp: (root.showMinimumSignal && rawAmp === 0) ? root.minimumSignalValue : rawAmp

      color: root.fillColor
      border.color: root.strokeColor
      border.width: root.strokeWidth
      antialiasing: true

      width: root.barSlotSize * 0.5
      height: root.height * amp
      x: index * root.barSlotSize + (root.barSlotSize * 0.25)
      y: root.height - height
    }
  }
}
