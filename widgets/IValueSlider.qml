import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.services

RowLayout {
  id: root

  property real from: 0
  property real to: 1
  property real value: 0
  property real stepSize: 0.01
  property var cutoutColor: ThemeService.palette.mSurface
  property bool snapAlways: true
  property real heightRatio: 0.7
  property string text: ""
  property real textSize: Style.appearance.font.size.small
  property real customHeight: -1
  property real customHeightRatio: -1

  // Signals
  signal moved(real value)
  signal pressedChanged(bool pressed, real value)

  spacing: Style.appearance.spacing.larger
  implicitHeight: root.customHeight > 0 ? root.customHeight : slider.implicitHeight

  ISlider {
    id: slider
    Layout.fillWidth: true
    from: root.from
    to: root.to
    value: root.value
    stepSize: root.stepSize
    cutoutColor: root.cutoutColor
    snapAlways: root.snapAlways
    heightRatio: root.customHeightRatio > 0 ? root.customHeightRatio : root.heightRatio
    onMoved: root.moved(value)
    onPressedChanged: root.pressedChanged(pressed, value)
  }

  IText {
    visible: root.text !== ""
    text: root.text
    pointSize: root.textSize
    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: 45
    horizontalAlignment: Text.AlignRight
  }
}
