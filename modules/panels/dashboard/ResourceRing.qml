import QtQuick
import qs.common
import qs.services
import qs.widgets

Item {
  id: root

  property real value: 0
  property string label: ""
  property string detail: Math.round(value) + "%"
  property color accent: ThemeService.palette.mPrimary

  implicitWidth: 104
  implicitHeight: 112

  Canvas {
    id: canvas
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    width: 78
    height: 78

    onPaint: {
      const ctx = getContext("2d");
      ctx.reset();
      ctx.lineWidth = 7;
      ctx.lineCap = "round";
      ctx.strokeStyle = ThemeService.palette.mSurfaceVariant;
      ctx.beginPath();
      ctx.arc(width / 2, height / 2, width / 2 - 6, -Math.PI * 0.75, Math.PI * 0.75);
      ctx.stroke();
      ctx.strokeStyle = root.accent;
      ctx.beginPath();
      ctx.arc(width / 2, height / 2, width / 2 - 6, -Math.PI * 0.75,
              -Math.PI * 0.75 + Math.PI * 1.5 * Math.max(0, Math.min(100, root.value)) / 100);
      ctx.stroke();
    }

    Connections {
      target: root
      function onValueChanged() { canvas.requestPaint(); }
      function onAccentChanged() { canvas.requestPaint(); }
    }
    Connections {
      target: ThemeService
      function onPaletteChanged() { canvas.requestPaint(); }
    }

    IText {
      anchors.centerIn: parent
      text: root.detail
      font.weight: Font.Bold
      font.pointSize: Style.font.size.normal
    }
  }

  IText {
    anchors.top: canvas.bottom
    anchors.topMargin: Style.spacing.small
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.label
    color: ThemeService.palette.mOnSurfaceVariant
    font.pointSize: Style.font.size.small
  }
}
