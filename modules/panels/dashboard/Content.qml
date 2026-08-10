pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets

Item {
  id: root

  required property ShellScreen screen
  property bool panelOpen: false
  signal closeRequested
  signal settingsRequested

  readonly property string consumerId: "dashboard-" + (screen?.name || "unknown")
  readonly property var tabs: DashboardService.tabs()
  readonly property real pageImplicitWidth: pageLoader.item ? pageLoader.item.implicitWidth : 720
  readonly property real pageImplicitHeight: pageLoader.item ? pageLoader.item.implicitHeight : 420
  readonly property real horizontalChrome: Style.padding.normal * 2
  readonly property real verticalChrome: Style.padding.normal * 2 + header.implicitHeight + Style.spacing.normal
  readonly property real maximumWidth: Math.max(360, screen.width - Style.padding.large * 2)
  readonly property real maximumHeight: Math.max(320, screen.height - Style.bar.innerHeight - Style.padding.large * 2)
  readonly property real contentPreferredWidth: Math.round(Math.min(maximumWidth, Math.max(pageImplicitWidth, header.implicitWidth) + horizontalChrome))
  readonly property real contentPreferredHeight: Math.round(Math.min(maximumHeight, pageImplicitHeight + verticalChrome))
  property real swipeDistance: 0

  onTabsChanged: DashboardService.select(DashboardService.currentTab)

  function updateConsumers() {
    const open = panelOpen && Settings.dashboard.enabled;
    const systemActive = open && (DashboardService.currentTab === "home" || DashboardService.currentTab === "performance");
    SystemUsageService.setConsumer(consumerId, systemActive);
    DistroService.setUptimeConsumer(consumerId, open && DashboardService.currentTab === "home");
    WeatherService.setConsumer(consumerId, open && (DashboardService.currentTab === "home" || DashboardService.currentTab === "weather"));
  }

  Component.onCompleted: updateConsumers()
  Component.onDestruction: {
    SystemUsageService.setConsumer(consumerId, false);
    DistroService.setUptimeConsumer(consumerId, false);
    WeatherService.setConsumer(consumerId, false);
  }
  onPanelOpenChanged: updateConsumers()

  Connections {
    target: DashboardService
    function onCurrentTabChanged() {
      root.updateConsumers();
    }
  }

  Connections {
    target: Settings.dashboard
    function onEnabledChanged() {
      if (!Settings.dashboard.enabled && root.panelOpen)
        root.closeRequested();
      root.updateConsumers();
    }
  }

  DragHandler {
    id: swipeHandler
    target: null
    acceptedDevices: PointerDevice.TouchScreen
    xAxis.enabled: true
    yAxis.enabled: false
    onActiveTranslationChanged: root.swipeDistance = activeTranslation.x
    onActiveChanged: {
      if (active)
        return;
      if (Math.abs(root.swipeDistance) >= 64)
        DashboardService.selectRelative(root.swipeDistance < 0 ? 1 : -1);
      root.swipeDistance = 0;
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.padding.normal
    spacing: Style.spacing.normal

    RowLayout {
      id: header
      Layout.fillWidth: true
      spacing: Style.spacing.small

      Repeater {
        model: root.tabs
        delegate: Rectangle {
          id: tab
          required property var modelData
          readonly property bool selected: DashboardService.currentTab === modelData.key
          implicitWidth: tabRow.implicitWidth + Style.padding.large * 2
          implicitHeight: 38
          radius: Style.rounding.small
          color: selected ? ThemeService.palette.mPrimary : (tabMouse.containsMouse ? ThemeService.palette.mSurfaceContainerHigh : "transparent")

          RowLayout {
            id: tabRow
            anchors.centerIn: parent
            spacing: Style.spacing.small
            IIcon { icon: tab.modelData.icon; color: tab.selected ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface; font.pointSize: Style.font.size.large }
            IText { text: tab.modelData.label; color: tab.selected ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface; font.weight: Font.Medium }
          }
          MouseArea { id: tabMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: DashboardService.select(tab.modelData.key) }
        }
      }

      Item { Layout.fillWidth: true }
      IIconButton { icon: "settings"; size: 38; onClicked: root.settingsRequested() }
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true

      Loader {
        id: pageLoader
        anchors.fill: parent
        asynchronous: false
        sourceComponent: {
          switch (DashboardService.currentTab) {
          case "media": return mediaPage;
          case "performance": return performancePage;
          case "weather": return weatherPage;
          default: return homePage;
          }
        }
      }

      WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
          if (Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y))
            DashboardService.selectRelative(event.angleDelta.x < 0 ? 1 : -1);
        }
      }
    }
  }

  Component { id: homePage; HomePage { screen: root.screen; active: root.panelOpen } }
  Component { id: mediaPage; MediaPage { screen: root.screen; active: root.panelOpen } }
  Component { id: performancePage; PerformancePage { active: root.panelOpen } }
  Component { id: weatherPage; WeatherPage {} }
}
