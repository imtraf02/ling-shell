import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.services

Rectangle {
  id: root

  property real value: 0
  property string icon: ""
  property string suffix: "%"
  property bool flat: false
  property real contentScale: 1.0

  property color circleColor: ThemeService.palette.mPrimary
  property color circleEndColor: ThemeService.palette.mOnSurface
  property color circleBackgroundColor: ThemeService.palette.mSurface
  property real circleWidth: 6
  property bool circleGradient: true

  property real valueFontSize: Style.appearance.font.size.smaller * 0.9
  property real iconSize: Style.appearance.font.size.smaller

  width: 68
  height: 92
  color: flat ? "transparent" : ThemeService.palette.mSurface
  radius: Settings.appearance.cornerRadius
  border.color: flat ? "transparent" : ThemeService.palette.mSurfaceVariant
  border.width: flat ? 0 : 1

  onValueChanged: gauge.requestPaint()

  onCircleColorChanged: gauge.requestPaint()
  onCircleEndColorChanged: gauge.requestPaint()
  onCircleBackgroundColorChanged: gauge.requestPaint()
  onCircleWidthChanged: gauge.requestPaint()
  onCircleGradientChanged: gauge.requestPaint()

  ColumnLayout {
    id: mainLayout
    anchors.fill: parent
    anchors.margins: Style.appearance.padding.small * root.contentScale
    spacing: 0

    Item {
      id: gaugeContainer
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.alignment: Qt.AlignCenter
      Layout.preferredWidth: 68 * root.contentScale
      Layout.preferredHeight: 68 * root.contentScale

      Canvas {
        id: gauge
        anchors.fill: parent
        renderStrategy: Canvas.Immediate

        onPaint: {
          const ctx = getContext("2d");
          const w = width, h = height;
          const cx = w / 2, cy = h / 2;
          const lineWidth = root.circleWidth * root.contentScale;
          const r = Math.min(w, h) / 2 - lineWidth / 2 - 2 * root.contentScale;
          const start = Math.PI * 5 / 6;
          const endBg = Math.PI * 13 / 6;

          ctx.reset();

          ctx.lineWidth = lineWidth;
          ctx.strokeStyle = root.circleBackgroundColor;
          ctx.beginPath();
          ctx.arc(cx, cy, r, start, endBg);
          ctx.stroke();

          const ratio = Math.max(0, Math.min(1, root.value / 100));
          const end = start + (endBg - start) * ratio;

          if (root.circleGradient) {
            const gradientStartRatio = 0.25;
            const gradientStart = start + (endBg - start) * gradientStartRatio;
            const startX = cx + r * Math.cos(gradientStart);
            const startY = cy + r * Math.sin(gradientStart);
            const endX = cx + r * Math.cos(endBg);
            const endY = cy + r * Math.sin(endBg);

            const gradient = ctx.createLinearGradient(startX, startY, endX, endY);
            gradient.addColorStop(0, root.circleColor);
            gradient.addColorStop(1, root.circleEndColor);
            ctx.strokeStyle = gradient;
          } else {
            ctx.strokeStyle = root.circleColor;
          }

          ctx.beginPath();
          ctx.arc(cx, cy, r, start, end);
          ctx.stroke();
        }
      }

      IText {
        id: valueLabel
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -4 * root.contentScale
        text: `${root.value}${root.suffix}`
        pointSize: root.valueFontSize * root.contentScale
        color: ThemeService.palette.mOnSurface
        horizontalAlignment: Text.AlignHCenter
      }

      IIcon {
        id: iconText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: valueLabel.bottom
        anchors.topMargin: 8 * root.contentScale
        icon: root.icon
        color: ThemeService.palette.mPrimary
        pointSize: root.iconSize * root.contentScale
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }
  }
}
