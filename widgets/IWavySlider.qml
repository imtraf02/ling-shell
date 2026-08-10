pragma ComponentBehavior: Bound

import QtQuick
import qs.common
import qs.services

Item {
  id: root

  property real from: 0
  property real to: 1
  property real value: from
  property bool animateWave: false
  property int waveFps: 24
  property real waveAmplitude: 2.4
  property real waveFrequency: 7
  property real handleWidth: pressed ? 1.5 : 3
  property real handleHeight: 24
  property real trackHeight: 6
  property real handleGap: 7
  property bool hovering: false

  readonly property bool pressed: pointerArea.pressed
  readonly property real normalizedValue: {
    const range = to - from;
    if (!isFinite(range) || range <= 0)
      return 0;
    return Math.max(0, Math.min(1, (value - from) / range));
  }

  signal interactionStarted(real value)
  signal interactionMoved(real value)
  signal interactionFinished(real value)

  property color highlightColor: root.enabled ? ThemeService.palette.mPrimary : Qt.alpha(ThemeService.palette.mOnSurface, 0.38)
  property color trackColor: root.enabled ? ThemeService.palette.mSurfaceVariant : Qt.alpha(ThemeService.palette.mOnSurface, 0.12)
  property color handleColor: root.enabled ? ThemeService.palette.mPrimary : Qt.alpha(ThemeService.palette.mOnSurface, 0.38)

  readonly property real effectiveWidth: Math.max(0, width - leftPadding - rightPadding)
  readonly property real handleCenter: leftPadding + normalizedValue * effectiveWidth

  property real leftPadding: 4
  property real rightPadding: 4
  implicitWidth: Style.widget.sliderWidth
  implicitHeight: 34

  function valueAt(pointerX) {
    if (effectiveWidth <= 0)
      return from;
    const ratio = Math.max(0, Math.min(1, (pointerX - leftPadding) / effectiveWidth));
    return from + ratio * (to - from);
  }

  MouseArea {
    id: pointerArea
    anchors.fill: parent
    enabled: root.enabled
    hoverEnabled: true
    cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
    onEntered: root.hovering = root.enabled
    onExited: root.hovering = false
    onPressed: mouse => {
      const nextValue = root.valueAt(mouse.x);
      root.value = nextValue;
      root.interactionStarted(nextValue);
    }
    onPositionChanged: mouse => {
      if (!pressed)
        return;
      const nextValue = root.valueAt(mouse.x);
      root.value = nextValue;
      root.interactionMoved(nextValue);
    }
    onReleased: mouse => {
      const nextValue = root.valueAt(mouse.x);
      root.value = nextValue;
      root.interactionFinished(nextValue);
    }
    onCanceled: root.interactionFinished(root.value)
  }

  Item {
    id: track
    anchors.fill: parent

    Canvas {
      id: wave

      property real phase: 0

      x: 0
      y: (parent.height - height) / 2
      width: Math.max(0, root.handleCenter - root.handleGap)
      height: Math.max(root.handleHeight, root.trackHeight + root.waveAmplitude * 2 + 4)
      visible: width > 1
      renderTarget: Canvas.Image

      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
      onPhaseChanged: requestPaint()
      onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (width <= 1)
          return;

        const centerY = height / 2;
        const fullLength = Math.max(1, root.width);
        ctx.strokeStyle = root.highlightColor;
        ctx.lineWidth = root.trackHeight;
        ctx.lineCap = "round";
        ctx.beginPath();
        for (let px = root.trackHeight / 2; px <= width - root.trackHeight / 2; px += 1.5) {
          const py = centerY + root.waveAmplitude * Math.sin(root.waveFrequency * 2 * Math.PI * px / fullLength + phase);
          if (px <= root.trackHeight / 2)
            ctx.moveTo(px, py);
          else
            ctx.lineTo(px, py);
        }
        ctx.stroke();
      }

      Connections {
        target: root
        function onHighlightColorChanged() { wave.requestPaint(); }
        function onWaveAmplitudeChanged() { wave.requestPaint(); }
        function onWaveFrequencyChanged() { wave.requestPaint(); }
      }

      Timer {
        interval: Math.max(16, Math.round(1000 / root.waveFps))
        repeat: true
        running: root.animateWave && root.visible && wave.visible
        onTriggered: wave.phase = (wave.phase + 0.20) % (Math.PI * 2)
      }
    }

    Rectangle {
      x: Math.min(parent.width, root.handleCenter + root.handleGap)
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, parent.width - x)
      height: root.trackHeight
      radius: height / 2
      color: root.trackColor
    }
  }

  Rectangle {
    implicitWidth: root.handleWidth
    implicitHeight: root.handleHeight
    x: root.handleCenter - width / 2
    anchors.verticalCenter: parent.verticalCenter
    radius: width / 2
    color: root.handleColor
    scale: root.hovering ? 1.06 : 1

    Behavior on implicitWidth {
      NumberAnimation {
        duration: 120
        easing.type: Easing.OutCubic
      }
    }
  }
}
