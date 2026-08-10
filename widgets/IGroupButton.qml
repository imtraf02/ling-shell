pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Rectangle {
  id: root

  property string text: ""
  property string icon: ""
  property bool selected: false
  property bool bounce: true
  property bool pill: true
  property bool down: false
  property real horizontalPadding: Style.padding.normal
  property real verticalPadding: Style.padding.small
  property real baseWidth: content.implicitWidth + horizontalPadding * 2
  property real baseHeight: Math.max(36, content.implicitHeight + verticalPadding * 2)
  property real clickedWidth: baseWidth * (1 + (parentGroup?.expansionRatio ?? 0.15))
  property real iconSize: Style.font.size.large
  property real fontSize: Style.font.size.small
  property int fontWeight: Font.Medium

  readonly property var parentGroup: parent
  readonly property int indexInParent: parentGroup?.children?.indexOf(root) ?? -1
  readonly property int groupCount: parentGroup?.childrenCount ?? 1
  readonly property bool isAtSide: indexInParent <= 0 || indexInParent >= groupCount - 1
  readonly property bool segmented: parentGroup?.segmented ?? false
  readonly property int pressedIndex: parentGroup?.pressedIndex ?? -1
  readonly property bool hovered: pointer.containsMouse
  readonly property real activeExpansion: {
    if (pressedIndex < 0 || !parentGroup?.children)
      return 0;
    const pressedButton = parentGroup.children[pressedIndex];
    if (!pressedButton || pressedButton.clickedWidth === undefined || pressedButton.baseWidth === undefined)
      return 0;
    return Math.max(0, pressedButton.clickedWidth - pressedButton.baseWidth);
  }
  readonly property real animatedWidth: {
    if (!bounce || pressedIndex < 0)
      return baseWidth;
    if (indexInParent === pressedIndex)
      return clickedWidth;
    if (Math.abs(indexInParent - pressedIndex) === 1) {
      const neighborCount = pressedIndex === 0 || pressedIndex === groupCount - 1 ? 1 : 2;
      return Math.max(24, baseWidth - activeExpansion / neighborCount);
    }
    return baseWidth;
  }
  readonly property real relaxedRadius: pill || selected ? height / 2 : Style.rounding.normal
  readonly property real pressedRadius: Math.min(Style.rounding.small, height / 2)
  readonly property real leadingRadius: down ? pressedRadius : (selected || !segmented || indexInParent === 0 ? relaxedRadius : pressedRadius)
  readonly property real trailingRadius: down ? pressedRadius : (selected || !segmented || indexInParent === groupCount - 1 ? relaxedRadius : pressedRadius)

  signal clicked
  signal rightClicked
  signal middleClicked

  Layout.fillWidth: parentGroup?.uniformCellSizes ?? false
  Layout.fillHeight: false
  Layout.alignment: Qt.AlignVCenter
  implicitWidth: animatedWidth
  implicitHeight: baseHeight
  activeFocusOnTab: enabled

  topLeftRadius: leadingRadius
  bottomLeftRadius: leadingRadius
  topRightRadius: trailingRadius
  bottomRightRadius: trailingRadius
  color: {
    if (!enabled)
      return ThemeService.palette.mPrimaryContainer;
    if (selected)
      return down ? ThemeService.palette.mPrimaryContainer : ThemeService.palette.mPrimary;
    if (down || hovered)
      return ThemeService.palette.mSurfaceVariant;
    return ThemeService.palette.mPrimaryContainer;
  }
  opacity: enabled ? 1 : 0.38
  border.width: activeFocus ? 2 : 0
  border.color: ThemeService.palette.mSecondary

  readonly property color foreground: {
    if (!enabled)
      return ThemeService.palette.mOnSurfaceVariant;
    if (selected && !down)
      return ThemeService.palette.mOnPrimary;
    if (selected)
      return ThemeService.palette.mOnPrimaryContainer;
    if (down || hovered)
      return ThemeService.palette.mOnSurfaceVariant;
    return ThemeService.palette.mOnPrimaryContainer;
  }

  Behavior on implicitWidth {
    NumberAnimation {
      duration: 180
      easing.type: Easing.BezierSpline
      easing.bezierCurve: Style.anim.curves.expressiveFastSpatial
    }
  }
  Behavior on topLeftRadius {
    NumberAnimation {
      duration: Style.anim.durations.small
      easing.type: Easing.BezierSpline
      easing.bezierCurve: Style.anim.curves.expressiveFastSpatial
    }
  }
  Behavior on topRightRadius { NumberAnimation { duration: Style.anim.durations.small; easing.type: Easing.BezierSpline; easing.bezierCurve: Style.anim.curves.expressiveFastSpatial } }
  Behavior on bottomLeftRadius { NumberAnimation { duration: Style.anim.durations.small; easing.type: Easing.BezierSpline; easing.bezierCurve: Style.anim.curves.expressiveFastSpatial } }
  Behavior on bottomRightRadius { NumberAnimation { duration: Style.anim.durations.small; easing.type: Easing.BezierSpline; easing.bezierCurve: Style.anim.curves.expressiveFastSpatial } }
  Behavior on color {
    ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
  }

  RowLayout {
    id: content
    anchors.centerIn: parent
    spacing: root.icon !== "" && root.text !== "" ? Style.spacing.small : 0

    IIcon {
      visible: root.icon !== ""
      icon: root.icon
      color: root.foreground
      font.pointSize: root.iconSize
      Behavior on color { ColorAnimation { duration: 150 } }
    }
    IText {
      visible: root.text !== ""
      text: root.text
      color: root.foreground
      font.pointSize: root.fontSize
      font.weight: root.fontWeight
      Behavior on color { ColorAnimation { duration: 150 } }
    }
  }

  function groupButtons() {
    if (!parentGroup?.children)
      return [];
    return parentGroup.children.filter(child => child && child.forceActiveFocus && child.visible && child.enabled);
  }

  function activateRelative(offset) {
    const buttons = groupButtons();
    const index = buttons.indexOf(root);
    if (index < 0 || buttons.length < 2)
      return;
    const target = buttons[(index + offset + buttons.length) % buttons.length];
    target.forceActiveFocus(Qt.TabFocusReason);
    if (segmented)
      target.clicked();
  }

  function finishPress() {
    down = false;
    if (parentGroup?.pressedIndex === indexInParent)
      parentGroup.pressedIndex = -1;
  }

  Keys.onPressed: event => {
    if (!enabled)
      return;
    if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
      activateRelative(-1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
      activateRelative(1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      down = true;
      if (parentGroup?.pressedIndex !== undefined)
        parentGroup.pressedIndex = indexInParent;
      event.accepted = true;
    }
  }
  Keys.onReleased: event => {
    if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      finishPress();
      clicked();
      event.accepted = true;
    }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.enabled
    hoverEnabled: true
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onPressed: event => {
      root.forceActiveFocus(Qt.MouseFocusReason);
      if (event.button !== Qt.LeftButton)
        return;
      root.down = true;
      if (root.parentGroup?.pressedIndex !== undefined)
        root.parentGroup.pressedIndex = root.indexInParent;
    }
    onReleased: event => {
      if (event.button === Qt.LeftButton)
        root.finishPress();
    }
    onCanceled: root.finishPress()
    onClicked: event => {
      if (event.button === Qt.LeftButton)
        root.clicked();
      else if (event.button === Qt.RightButton)
        root.rightClicked();
      else if (event.button === Qt.MiddleButton)
        root.middleClicked();
    }
  }
}
