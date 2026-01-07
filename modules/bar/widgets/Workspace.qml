pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Quickshell
import qs.commons
import qs.services
import qs.widgets

Item {
  id: root

  property ShellScreen screen

  property ListModel localWorkspaces: ListModel {}
  property real masterProgress: 0.0
  property bool effectsActive: false
  property color effectColor: ThemeService.palette.mPrimary

  property int horizontalPadding: Style.appearance.padding.small
  property int spacingBetweenPills: Style.appearance.spacing.small

  property int wheelAccumulatedDelta: 0
  property bool wheelCooldown: false

  implicitWidth: {
    let total = 0;
    for (var i = 0; i < localWorkspaces.count; i++) {
      const ws = localWorkspaces.get(i);
      total += getWorkspaceWidth(ws);
    }
    total += Math.max(localWorkspaces.count - 1, 0) * spacingBetweenPills;
    total += horizontalPadding * 2;
    return Math.round(total);
  }
  implicitHeight: Style.bar.innerHeight

  signal workspaceChanged(int workspaceId, color accentColor)

  Component.onCompleted: {
    refreshWorkspaces();
  }

  onScreenChanged: refreshWorkspaces()

  Connections {
    target: CompositorService
    function onWorkspacesChanged() {
      root.refreshWorkspaces();
    }
  }

  function refreshWorkspaces() {
    localWorkspaces.clear();
    if (screen !== null) {
      for (var i = 0; i < CompositorService.workspaces.count; i++) {
        const ws = CompositorService.workspaces.get(i);
        if (ws.output.toLowerCase() === screen.name.toLowerCase()) {
          localWorkspaces.append(ws);
        }
      }
    }
    workspaceRepeater.model = localWorkspaces;
    updateWorkspaceFocus();
  }

  function updateWorkspaceFocus() {
    for (var i = 0; i < localWorkspaces.count; i++) {
      const ws = localWorkspaces.get(i);
      if (ws.isFocused === true) {
        root.triggerUnifiedWave();
        root.workspaceChanged(ws.id, ThemeService.palette.mPrimary);
        break;
      }
    }
  }

  function getWorkspaceWidth(ws) {
    const d = Style.bar.innerHeight;
    const factor = ws.isActive ? 2.2 : 1;

    return d * factor;
  }

  function triggerUnifiedWave() {
    effectColor = ThemeService.palette.mPrimary;
    masterAnimation.restart();
  }

  function getFocusedLocalIndex() {
    for (var i = 0; i < localWorkspaces.count; i++) {
      if (localWorkspaces.get(i).isFocused === true)
        return i;
    }
    return -1;
  }

  function switchByOffset(offset) {
    if (localWorkspaces.count === 0)
      return;
    var current = getFocusedLocalIndex();
    if (current < 0)
      current = 0;
    var next = (current + offset) % localWorkspaces.count;
    if (next < 0)
      next = localWorkspaces.count - 1;
    const ws = localWorkspaces.get(next);
    if (ws && ws.idx !== undefined)
      CompositorService.switchToWorkspace(ws);
  }

  SequentialAnimation {
    id: masterAnimation
    PropertyAction {
      target: root
      property: "effectsActive"
      value: true
    }
    NumberAnimation {
      target: root
      property: "masterProgress"
      from: 0.0
      to: 1.0
      duration: Style.appearance.anim.durations.large * 2
      easing.type: Easing.OutQuint
    }
    PropertyAction {
      target: root
      property: "effectsActive"
      value: false
    }
    PropertyAction {
      target: root
      property: "masterProgress"
      value: 0.0
    }
  }

  Timer {
    id: wheelDebounce
    interval: 150
    repeat: false
    onTriggered: {
      root.wheelCooldown = false;
      root.wheelAccumulatedDelta = 0;
    }
  }

  Rectangle {
    id: workspaceBackground
    anchors.fill: parent
    radius: Settings.appearance.cornerRadius
    color: ThemeService.palette.mSurfaceContainer

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
  }

  WheelHandler {
    id: wheelHandler
    target: root
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function (event) {
      if (root.wheelCooldown)
        return;
      // Prefer vertical delta, fall back to horizontal if needed
      var dy = event.angleDelta.y;
      var dx = event.angleDelta.x;
      var useDy = Math.abs(dy) >= Math.abs(dx);
      var delta = useDy ? dy : dx;
      // One notch is typically 120
      root.wheelAccumulatedDelta += delta;
      var step = 120;
      if (Math.abs(root.wheelAccumulatedDelta) >= step) {
        var direction = root.wheelAccumulatedDelta > 0 ? -1 : 1;
        // For vertical layout, natural mapping: wheel up -> previous, down -> next (already handled by sign)
        // For horizontal layout, same mapping using vertical wheel
        root.switchByOffset(direction);
        root.wheelCooldown = true;
        wheelDebounce.restart();
        root.wheelAccumulatedDelta = 0;
        event.accepted = true;
      }
    }
  }

  Row {
    id: pill
    spacing: root.spacingBetweenPills
    anchors.verticalCenter: workspaceBackground.verticalCenter
    x: root.horizontalPadding

    Repeater {
      id: workspaceRepeater
      model: root.localWorkspaces

      Item {
        id: workspacePillContainer

        required property var model

        width: root.getWorkspaceWidth(model)
        height: Math.max(1, Math.round(root.implicitHeight * 0.48))

        Rectangle {
          id: pillRect
          anchors.fill: parent
          radius: Settings.appearance.cornerRadius
          scale: workspacePillContainer.model.isActive ? 1.0 : 0.9
          z: 0

          color: {
            if (workspacePillContainer.model.isFocused)
              return ThemeService.palette.mPrimary;
            if (workspacePillContainer.model.isUrgent)
              return ThemeService.palette.mError;
            if (workspacePillContainer.model.isOccupied)
              return ThemeService.palette.mSecondary;
            return Qt.alpha(ThemeService.palette.mSecondary, 0.6);
          }

          Loader {
            active: true
            sourceComponent: Component {
              IText {
                x: (pillRect.width - width) / 2
                y: (pillRect.height - height) / 2 + (height - contentHeight) / 2

                text: workspacePillContainer.model.idx.toString()

                pointSize: workspacePillContainer.model.isActive ? workspacePillContainer.height * 0.45 : workspacePillContainer.height * 0.42

                font.capitalization: Font.AllUppercase
                wrapMode: Text.Wrap

                color: ThemeService.palette.mOnPrimary
              }
            }
          }

          MouseArea {
            id: pillMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: {
              CompositorService.switchToWorkspace(workspacePillContainer.model);
            }
          }

          Behavior on width {
            IAnim {}
          }
          Behavior on height {
            IAnim {}
          }
          Behavior on scale {
            IAnim {}
          }
          Behavior on color {
            ICAnim {}
          }
          Behavior on opacity {
            IAnim {}
          }
          Behavior on radius {
            IAnim {}
          }
        }

        // Burst outline effect
        Rectangle {
          id: pillBurst
          anchors.centerIn: workspacePillContainer
          width: workspacePillContainer.width + 18 * root.masterProgress * scale
          height: workspacePillContainer.height + 18 * root.masterProgress * scale
          radius: Settings.appearance.cornerRadius

          color: "transparent"
          border.color: root.effectColor
          border.width: Math.max(1, Math.round(2 + 6 * (1.0 - root.masterProgress)))

          opacity: root.effectsActive && workspacePillContainer.model.isFocused ? (1.0 - root.masterProgress) * 0.7 : 0

          visible: root.effectsActive && workspacePillContainer.model.isFocused
          z: 1
        }
      }

      Behavior on width {
        IAnim {}
      }
      Behavior on height {
        IAnim {}
      }
    }
  }
}
