pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
  id: root
  property color fillColor: ThemeService.palette.mPrimary
  property color strokeColor: ThemeService.palette.mOnSurface
  property int strokeWidth: 0
  property var values: []
  property real barWidthRatio: 0.56

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

      readonly property real sourceAmp: Number(root.values[valueIndex] ?? 0)
      readonly property real rawAmp: isFinite(sourceAmp) ? Math.max(0, Math.min(1, sourceAmp)) : 0
      readonly property real amp: root.showMinimumSignal
        ? Math.max(root.minimumSignalValue, rawAmp)
        : rawAmp

      color: root.fillColor
      border.color: root.strokeColor
      border.width: root.strokeWidth
      antialiasing: false

      width: Math.max(1, root.barSlotSize * Math.max(0.1, Math.min(0.95, root.barWidthRatio)))
      height: Math.max(root.showMinimumSignal ? 2 : 0, root.height * amp)
      x: index * root.barSlotSize + (root.barSlotSize - width) / 2
      y: root.height - height
      radius: Math.min(width / 2, height / 2)
      visible: root.barSlotSize > 0 && height > 0
    }
  }
}
