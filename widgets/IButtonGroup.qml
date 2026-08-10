pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Rectangle {
  id: root

  default property alias groupData: groupLayout.data
  property bool segmented: false
  property bool uniformCellSizes: false
  property real spacing: segmented ? 2 : Style.spacing.small
  property real padding: 0
  property real expansionRatio: 0.15
  property int pressedIndex: -1
  readonly property alias childrenCount: groupLayout.childrenCount

  readonly property real contentWidth: {
    let visibleCount = 0;
    let total = 0;
    let maximum = 0;
    for (let i = 0; i < groupLayout.children.length; i++) {
      const child = groupLayout.children[i];
      if (!child.visible)
        continue;
      const base = child.baseWidth !== undefined ? child.baseWidth : (child.implicitWidth || child.width);
      visibleCount++;
      total += base;
      maximum = Math.max(maximum, base);
    }
    if (uniformCellSizes)
      total = maximum * visibleCount;
    return total + Math.max(0, visibleCount - 1) * spacing;
  }

  implicitWidth: contentWidth + padding * 2
  implicitHeight: groupLayout.implicitHeight + padding * 2
  radius: 0
  color: "transparent"
  clip: false

  Behavior on color { ICAnim {} }

  RowLayout {
    id: groupLayout
    anchors.fill: parent
    anchors.margins: root.padding
    spacing: root.spacing
    uniformCellSizes: root.uniformCellSizes

    property alias pressedIndex: root.pressedIndex
    property alias segmented: root.segmented
    property alias expansionRatio: root.expansionRatio
    readonly property int childrenCount: children.length
  }
}
