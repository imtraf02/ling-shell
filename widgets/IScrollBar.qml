import QtQuick
import QtQuick.Templates
import qs.commons
import qs.services

ScrollBar {
  id: root

  required property Flickable flickable
  property bool shouldBeActive
  property real nonAnimPosition
  property bool animating

  onHoveredChanged: {
    if (hovered)
      shouldBeActive = true;
    else
      shouldBeActive = flickable.moving;
  }

  onPositionChanged: {
    if (position === nonAnimPosition)
      animating = false;
    else if (!animating)
      nonAnimPosition = position;
  }

  position: nonAnimPosition
  implicitWidth: Style.appearance.padding.small

  contentItem: Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    opacity: {
      if (root.size === 1)
        return 0;
      if (fullMouse.pressed)
        return 1;
      if (mouse.containsMouse)
        return 0.8;
      if (root.policy === ScrollBar.AlwaysOn || root.shouldBeActive)
        return 0.6;
      return 0;
    }
    radius: Style.appearance.rounding.full
    color: ThemeService.palette.mSecondary

    MouseArea {
      id: mouse

      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
    }

    Behavior on opacity {
      IAnim {}
    }

    Behavior on color {
      ICAnim {}
    }
  }

  Connections {
    target: root.flickable

    function onMovingChanged(): void {
      if (root.flickable.moving)
        root.shouldBeActive = true;
      else
        hideDelay.restart();
    }
  }

  Timer {
    id: hideDelay

    interval: 600
    onTriggered: root.shouldBeActive = root.flickable.moving || root.hovered
  }

  MouseArea {
    id: fullMouse

    anchors.fill: parent
    preventStealing: true

    onPressed: event => {
      root.animating = true;
      root.nonAnimPosition = Math.max(0, Math.min(1 - root.size, event.y / root.height - root.size / 2));
    }

    onPositionChanged: event => root.nonAnimPosition = Math.max(0, Math.min(1 - root.size, event.y / root.height - root.size / 2))

    onWheel: event => {
      root.animating = true;
      if (event.angleDelta.y > 0)
        root.nonAnimPosition = Math.max(0, root.nonAnimPosition - 0.1);
      else if (event.angleDelta.y < 0)
        root.nonAnimPosition = Math.min(1 - root.size, root.nonAnimPosition + 0.1);
    }
  }

  Behavior on position {
    enabled: !fullMouse.pressed

    IAnim {}
  }
}
