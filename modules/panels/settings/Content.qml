pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.commons
import qs.widgets
import qs.services
import "tabs"

RowLayout {
  id: root

  required property var panel

  readonly property real padding: Config.appearance.padding.normal
  readonly property real spacing: Config.appearance.spacing.small

  readonly property var tabComponents: ({
      [Panel.Tab.About]: aboutTab,
      [Panel.Tab.System]: systemTab,
      [Panel.Tab.Personalization]: personalizationTab,
      [Panel.Tab.Bar]: barTab,
      [Panel.Tab.Display]: displayTab,
      [Panel.Tab.Audio]: audioTab,
      [Panel.Tab.Keybinds]: keybindsTab,
      [Panel.Tab.Network]: networkTab
    })

  function selectNextTab() {
    if (panel.tabsModel.length > 0) {
      panel.currentTabIndex = (panel.currentTabIndex + 1) % panel.tabsModel.length;
    }
  }

  function selectPreviousTab() {
    if (panel.tabsModel.length > 0) {
      panel.currentTabIndex = (panel.currentTabIndex - 1 + panel.tabsModel.length) % panel.tabsModel.length;
    }
  }

  Rectangle {
    id: sidebar

    clip: true
    Layout.preferredWidth: 220
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop
    color: ThemeService.palette.mSurface
    radius: Settings.appearance.cornerRadius

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.NoButton
      property int wheelAccumulator: 0
      onWheel: wheel => {
        wheelAccumulator += wheel.angleDelta.y;
        if (wheelAccumulator >= 120) {
          root.selectPreviousTab();
          wheelAccumulator = 0;
        } else if (wheelAccumulator <= -120) {
          root.selectNextTab();
          wheelAccumulator = 0;
        }
        wheel.accepted = true;
      }
    }

    ColumnLayout {
      anchors.fill: parent
      spacing: root.spacing

      Repeater {
        id: sections
        model: root.panel.tabsModel
        delegate: Rectangle {
          id: tabItem

          required property int index
          required property var modelData

          Layout.fillWidth: true
          Layout.preferredHeight: tabEntryRow.implicitHeight + root.padding * 2
          radius: Settings.appearance.cornerRadius
          color: selected ? ThemeService.palette.mPrimary : (tabItem.hovering ? ThemeService.palette.mPrimary : ThemeService.palette.mSurface)

          readonly property bool selected: index === root.panel.currentTabIndex
          property bool hovering: false
          property color tabTextColor: selected ? ThemeService.palette.mOnPrimary : (tabItem.hovering ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface)

          Behavior on color {
            ICAnim {}
          }

          RowLayout {
            id: tabEntryRow
            anchors.fill: parent
            anchors.leftMargin: root.padding
            anchors.rightMargin: root.padding
            spacing: root.spacing

            IIcon {
              icon: tabItem.modelData.icon
              color: tabItem.tabTextColor
              pointSize: Config.appearance.font.size.large
            }

            IText {
              text: tabItem.modelData.label
              color: tabItem.tabTextColor
              pointSize: Config.appearance.font.size.normal
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onEntered: tabItem.hovering = true
            onExited: tabItem.hovering = false
            onCanceled: tabItem.hovering = false
            onClicked: root.panel.currentTabIndex = tabItem.index
          }
        }
      }

      Item {
        Layout.fillHeight: true
      }
    }
  }

  Rectangle {
    id: contentPane
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop
    radius: Settings.appearance.cornerRadius
    color: ThemeService.palette.mSurfaceContainer

    ColumnLayout {
      id: contentLayout
      anchors.fill: parent
      anchors.margins: root.padding
      spacing: root.spacing

      RowLayout {
        id: headerRow
        Layout.fillWidth: true
        spacing: root.spacing

        IIcon {
          icon: root.panel.tabsModel[root.panel.currentTabIndex]?.icon
          color: ThemeService.palette.mPrimary
          pointSize: Config.appearance.font.size.large
        }

        IText {
          text: root.panel.tabsModel[root.panel.currentTabIndex]?.label || ""
          pointSize: Config.appearance.font.size.large
          color: ThemeService.palette.mPrimary
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
        }

        IIconButton {
          icon: "close"
          Layout.alignment: Qt.AlignVCenter
          onClicked: root.panel.close()
        }
      }

      IDivider {
        Layout.fillWidth: true
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "transparent"

        IFlickable {
          anchors.fill: parent
          clip: true
          contentWidth: parent.width
          contentHeight: currentTabLoader.item ? currentTabLoader.item.implicitHeight : 0
          boundsBehavior: Flickable.StopAtBounds

          Loader {
            id: currentTabLoader
            anchors.fill: parent
            anchors.margins: root.padding
            asynchronous: true

            sourceComponent: {
              if (!active)
                return null;
              const tabId = root.panel.tabsModel[root.panel.currentTabIndex].id;
              return root.tabComponents[tabId] || null;
            }
          }
        }
      }
    }
  }

  Component {
    id: aboutTab
    AboutTab {}
  }

  Component {
    id: systemTab
    SystemTab {
      panel: root.panel
    }
  }

  Component {
    id: personalizationTab
    PersonalizationTab {
      panel: root.panel
    }
  }

  Component {
    id: barTab
    BarTab {}
  }

  Component {
    id: displayTab
    DisplayTab {}
  }

  Component {
    id: audioTab
    AudioTab {}
  }

  Component {
    id: networkTab
    NetworkTab {}
  }

  Component {
    id: keybindsTab
    KeybindsTab {}
  }
}
