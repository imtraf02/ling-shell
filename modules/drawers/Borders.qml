pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.commons
import qs.services

Item {
  id: root

  required property Item bar

  anchors.fill: parent

  Rectangle {
    anchors.fill: parent
    color: ThemeService.palette.mSurface

    layer.enabled: true
    layer.effect: MultiEffect {
      maskSource: mask
      maskEnabled: true
      maskInverted: true
      maskThresholdMin: 0.5
      maskSpreadAtMin: 1
    }
  }

  Item {
    id: mask

    anchors.fill: parent
    layer.enabled: true
    visible: false

    Rectangle {
      anchors.fill: parent
      anchors.margins: Settings.appearance.thickness
      anchors.topMargin: root.bar.implicitHeight
      radius: Settings.appearance.cornerRadius
    }
  }
}
