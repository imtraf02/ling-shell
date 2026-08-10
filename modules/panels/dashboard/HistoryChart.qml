import QtQuick
import qs.services

Canvas {
  id: root
  property var values: []
  property color lineColor: ThemeService.palette.mPrimary
  property color gridColor: Qt.alpha(ThemeService.palette.mOutline, 0.14)

  antialiasing: true
  onValuesChanged: requestPaint()
  onLineColorChanged: requestPaint()
  onGridColorChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  onPaint: {
    const ctx = getContext("2d");
    ctx.reset();
    ctx.lineWidth = 1;
    ctx.strokeStyle = gridColor;
    for (let i = 1; i < 4; i++) {
      const guideY = height * i / 4;
      ctx.beginPath();
      ctx.moveTo(0, guideY);
      ctx.lineTo(width, guideY);
      ctx.stroke();
    }
    if (!values || values.length < 2)
      return;
    const step = width / Math.max(1, values.length - 1);
    ctx.beginPath();
    ctx.moveTo(0, height);
    for (let i = 0; i < values.length; i++)
      ctx.lineTo(i * step, height - Math.max(0, Math.min(100, values[i])) / 100 * height);
    ctx.lineTo(width, height);
    ctx.closePath();
    ctx.fillStyle = Qt.alpha(lineColor, 0.12);
    ctx.fill();
    ctx.beginPath();
    for (let i = 0; i < values.length; i++) {
      const x = i * step;
      const y = height - Math.max(0, Math.min(100, values[i])) / 100 * height;
      if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
    ctx.lineWidth = 2;
    ctx.lineJoin = "round";
    ctx.strokeStyle = lineColor;
    ctx.stroke();
  }
}
