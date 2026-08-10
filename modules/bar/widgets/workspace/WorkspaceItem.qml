pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets
import qs.utils

Item {
  id: root

  required property var workspace
  required property int activeWsIdx

  property var windows: []

  implicitWidth: layout.implicitWidth + (Settings.bar.workspace.showWindows ? Style.padding.small : 0)
  implicitHeight: layout.implicitHeight

  function refreshWindows() {
    windows = workspace ? (CompositorService.windowsByWorkspace[workspace.id] || []) : [];
  }

  Connections {
    target: CompositorService
    function onWindowListChanged() {
      if (Settings.bar.workspace.showWindows)
        root.refreshWindows();
    }
  }

  onActiveWsIdxChanged: {
    if (Settings.bar.workspace.showWindows)
      root.refreshWindows();
  }

  onWorkspaceChanged: {
    if (Settings.bar.workspace.showWindows)
      root.refreshWindows();
  }

  RowLayout {
    id: layout

    Layout.alignment: Qt.AlignVCenter

    spacing: 0

    IText {
      Layout.preferredWidth: Style.bar.innerHeight - Style.padding.small * 2
      text: {
        if (root.workspace) {
          if (root.workspace.isFocused)
            return Settings.bar.workspace.activeLabel;
          if (root.workspace.isOccupied)
            return Settings.bar.workspace.occupiedLabel;
        }
        return Settings.bar.workspace.label;
      }
      horizontalAlignment: Qt.AlignHCenter
      color: {
        if (root.workspace) {
          if (root.workspace.isFocused)
            return ThemeService.palette.mPrimary;

          if (root.workspace.isOccupied)
            return ThemeService.palette.mSecondary;
        }

        return Qt.alpha(ThemeService.palette.mSecondary, 0.6);
      }
    }

    Loader {
      active: Settings.bar.workspace.showWindows
      visible: active
      asynchronous: true

      Layout.leftMargin: -Style.bar.innerHeight / 10
      Layout.alignment: Qt.AlignVCenter
      Layout.fillWidth: true

      sourceComponent: Row {
        spacing: 0

        Repeater {
          model: root.windows
          IIcon {
            required property var modelData

            icon: Icons.getAppCategoryIcon(modelData.appId, "terminal")
            color: {
              if (root.workspace) {
                if (root.workspace.isFocused)
                  return ThemeService.palette.mPrimary;

                if (root.workspace.isOccupied)
                  return ThemeService.palette.mSecondary;
              }

              return Qt.alpha(ThemeService.palette.mSecondary, 0.6);
            }
          }
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true
    onClicked: {
      if (root.workspace)
        CompositorService.switchToWorkspace(root.workspace);
    }
  }
}
