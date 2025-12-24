import QtQuick
import qs.config
import qs.services

Item {
  id: root
  property bool running: true
  property color color: ThemeService.palette.mPrimary
  property int size: Config.appearance.widget.size
  property int strokeWidth: 3
  property int duration: Config.appearance.anim.durations.large * 2

  property real internalStrokeWidth: strokeWidth
  property int animState: 0

  implicitWidth: size
  implicitHeight: size

  Component.onCompleted: {
    if (running) {
      running = false;
      running = true;
    }
  }

  onRunningChanged: {
    if (running) {
      animState = 1;
    } else {
      if (animState === 1)
        animState = 2;
    }
  }

  states: State {
    name: "stopped"
    when: !root.running
    PropertyChanges {
      root.opacity: 0
      root.internalStrokeWidth: root.strokeWidth / 3
    }
  }

  transitions: Transition {
    NumberAnimation {
      properties: "opacity,internalStrokeWidth"
      duration: Config.appearance.anim.durations.normal
      easing.type: Easing.InOutQuad
    }
  }

  Canvas {
    id: canvas
    anchors.fill: parent

    onPaint: {
      var ctx = getContext("2d");
      ctx.reset();
      var centerX = width / 2;
      var centerY = height / 2;
      var radius = Math.min(width, height) / 2 - root.internalStrokeWidth / 2;

      ctx.strokeStyle = root.color;
      ctx.lineWidth = Math.max(1, root.internalStrokeWidth);
      ctx.lineCap = "round";

      // Draw arc with gap (270 degrees with 90 degree gap)
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, -Math.PI / 2 + rotationAngle, -Math.PI / 2 + rotationAngle + Math.PI * 1.5);
      ctx.stroke();
    }

    property real rotationAngle: 0

    onRotationAngleChanged: {
      requestPaint();
    }

    NumberAnimation {
      target: canvas
      property: "rotationAngle"
      running: root.animState !== 0 // Running when not Stopped
      from: 0
      to: 2 * Math.PI
      duration: root.duration
      loops: Animation.Infinite
    }
  }
}
