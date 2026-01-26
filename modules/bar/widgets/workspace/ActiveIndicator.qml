import QtQuick
import qs.common
import qs.services
import qs.widgets

Rectangle {
  id: root

  required property int activeWsIdx
  required property Repeater workspaces
  required property Item mask

  readonly property int displayIndex: {
    const groupStart = Math.floor((activeWsIdx - 1) / Settings.bar.workspace.shown) * Settings.bar.workspace.shown;
    const idx = (activeWsIdx - 1) - groupStart;
    return Math.max(0, Math.min(idx, Settings.bar.workspace.shown - 1));
  }

  property int previousIndex: 0

  readonly property var currentItem: workspaces.itemAt(displayIndex)
  readonly property real targetX: currentItem?.x ?? 0
  readonly property real targetWidth: currentItem?.width ?? 0

  property real animX: targetX
  property real animWidth: targetWidth

  Component.onCompleted: {
    previousIndex = displayIndex;
    animX = targetX;
    animWidth = targetWidth;
  }

  onDisplayIndexChanged: {
    if (Settings.bar.workspace.activeTrail) {
      const prevItem = workspaces.itemAt(previousIndex);
      const currItem = workspaces.itemAt(displayIndex);

      if (prevItem && currItem) {
        if (displayIndex > previousIndex) {
          animX = prevItem.x;
          animWidth = currItem.x + currItem.width - prevItem.x;
        } else {
          animX = currItem.x;
          animWidth = prevItem.x + prevItem.width - currItem.x;
        }
      }

      Qt.callLater(() => {
        animX = targetX;
        animWidth = targetWidth;
      });
    } else {
      animX = targetX;
      animWidth = targetWidth;
    }

    previousIndex = displayIndex;
  }

  onTargetXChanged: if (!Settings.bar.workspace.activeTrail)
    animX = targetX
  onTargetWidthChanged: if (!Settings.bar.workspace.activeTrail)
    animWidth = targetWidth

  clip: true
  x: animX + mask.x
  implicitWidth: animWidth
  implicitHeight: Style.bar.innerHeight - Style.padding.small
  radius: Settings.appearance.cornerRadius
  color: ThemeService.palette.mPrimary

  IColouriser {
    source: root.mask
    sourceColor: ThemeService.palette.mOnSurface
    colorizationColor: ThemeService.palette.mOnPrimary
    x: -root.animX
    y: 0
    implicitWidth: root.mask.implicitWidth
    implicitHeight: root.mask.implicitHeight
    anchors.verticalCenter: parent.verticalCenter
  }

  Behavior on animX {
    IAnim {
      duration: Settings.bar.workspace.activeTrail ? Style.anim.durations.normal * 2 : Style.anim.durations.normal
      easing.bezierCurve: Style.anim.curves.emphasized
    }
  }

  Behavior on animWidth {
    IAnim {
      duration: Settings.bar.workspace.activeTrail ? Style.anim.durations.normal * 2 : Style.anim.durations.normal
      easing.bezierCurve: Style.anim.curves.emphasized
    }
  }
}
