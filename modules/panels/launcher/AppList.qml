pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.common
import qs.services
import qs.widgets
import qs.modules.panels.launcher.services
import qs.modules.panels.launcher.items

IListView {
  id: root

  required property var panel
  required property ITextInput searchInput

  IScrollBar.vertical: IScrollBar {
    flickable: root
  }

  model: ScriptModel {
    id: model

    onValuesChanged: root.currentIndex = 0
  }

  spacing: Style.spacing.small
  orientation: Qt.Vertical

  implicitHeight: (Style.launcher.itemHeight + spacing) * Math.min(7, count) - spacing

  preferredHighlightBegin: 0
  preferredHighlightEnd: height
  highlightRangeMode: ListView.ApplyRange

  highlightFollowsCurrentItem: false
  highlight: Rectangle {
    color: ThemeService.palette.mOnSurface
    radius: Style.rounding.small
    opacity: 0.08

    y: root.currentItem?.y ?? 0
    implicitWidth: root.width
    implicitHeight: root.currentItem?.implicitHeight ?? 0

    Behavior on y {
      IAnim {
        duration: Style.anim.durations.normal
        easing.bezierCurve: Style.anim.curves.expressiveDefaultSpatial
      }
    }
  }

  state: {
    const text = root.searchInput.inputItem.text;
    const prefix = Settings.launcher.actionPrefix;
    if (text.startsWith(prefix)) {
      for (const action of ["calc"])
        if (text.startsWith(`${prefix}${action} `))
          return action;
      return "actions";
    }

    return "apps";
  }

  onStateChanged: {}

  states: [
    State {
      name: "apps"

      PropertyChanges {
        model.values: AppsService.search(root.searchInput.inputItem.text)
        root.delegate: appItem
      }
    },
    State {
      name: "actions"

      PropertyChanges {
        model.values: ActionsService.query(root.searchInput.inputItem.text)
        root.delegate: actionItem
      }
    }
  ]

  transitions: Transition {
    SequentialAnimation {
      ParallelAnimation {
        IAnim {
          target: root
          property: "opacity"
          from: 1
          to: 0
          duration: Style.anim.durations.small
          easing.bezierCurve: Style.anim.curves.standardAccel
        }
        IAnim {
          target: root
          property: "scale"
          from: 1
          to: 0.9
          duration: Style.anim.durations.small
          easing.bezierCurve: Style.anim.curves.standardAccel
        }
      }
      PropertyAction {
        targets: [model, root]
        properties: "values,delegate"
      }
      ParallelAnimation {
        IAnim {
          target: root
          property: "opacity"
          from: 0
          to: 1
          duration: Style.anim.durations.small
          easing.bezierCurve: Style.anim.curves.standardDecel
        }
        IAnim {
          target: root
          property: "scale"
          from: 0.9
          to: 1
          duration: Style.anim.durations.small
          easing.bezierCurve: Style.anim.curves.standardDecel
        }
      }
      PropertyAction {
        targets: [root.add, root.remove]
        property: "enabled"
        value: true
      }
    }
  }

  add: Transition {
    enabled: !root.state

    IAnim {
      properties: "opacity,scale"
      from: 0
      to: 1
    }
  }

  remove: Transition {
    enabled: !root.state

    IAnim {
      properties: "opacity,scale"
      from: 1
      to: 0
    }
  }

  move: Transition {
    IAnim {
      property: "y"
    }
    IAnim {
      properties: "opacity,scale"
      to: 1
    }
  }

  addDisplaced: Transition {
    IAnim {
      property: "y"
      duration: Style.anim.durations.small
    }
    IAnim {
      properties: "opacity,scale"
      to: 1
    }
  }

  displaced: Transition {
    IAnim {
      property: "y"
    }
    IAnim {
      properties: "opacity,scale"
      to: 1
    }
  }

  Component {
    id: appItem

    AppItem {
      onClicked: root.panel.close()
    }
  }

  Component {
    id: actionItem

    ActionItem {
      list: root
    }
  }
}
