pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.commons
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

  spacing: Config.appearance.spacing.small
  orientation: Qt.Vertical

  implicitHeight: (Config.launcher.sizes.itemHeight + spacing) * Math.min(7, count) - spacing

  preferredHighlightBegin: 0
  preferredHighlightEnd: height
  highlightRangeMode: ListView.ApplyRange

  highlightFollowsCurrentItem: false
  highlight: Rectangle {
    color: ThemeService.palette.mOnSurface
    radius: Settings.appearance.cornerRadius
    opacity: 0.08

    y: root.currentItem?.y ?? 0
    implicitWidth: root.width
    implicitHeight: root.currentItem?.implicitHeight ?? 0

    Behavior on y {
      IAnim {
        duration: Config.appearance.anim.durations.normal
        easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
      }
    }
  }

  state: {
    const text = root.searchInput.inputItem.text;
    const prefix = Config.launcher.actionPrefix;
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
          duration: Config.appearance.anim.durations.small
          easing.bezierCurve: Config.appearance.anim.curves.standardAccel
        }
        IAnim {
          target: root
          property: "scale"
          from: 1
          to: 0.9
          duration: Config.appearance.anim.durations.small
          easing.bezierCurve: Config.appearance.anim.curves.standardAccel
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
          duration: Config.appearance.anim.durations.small
          easing.bezierCurve: Config.appearance.anim.curves.standardDecel
        }
        IAnim {
          target: root
          property: "scale"
          from: 0.9
          to: 1
          duration: Config.appearance.anim.durations.small
          easing.bezierCurve: Config.appearance.anim.curves.standardDecel
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
      duration: Config.appearance.anim.durations.small
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
