pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets
import qs.modules.panels.settings.tabs as SettingsTabs

Item {
  id: root

  property int currentTabIndex: 0
  property int previousTabIndex: 0
  property var tabsModel: []
  property bool expanded: width >= 840
  property real tabOpacity: 1.0
  property real tabOffset: 0

  readonly property int iconSize: Math.max(1, Math.round(Style.widget.size * 0.8))
  readonly property var currentTab: tabsModel[currentTabIndex] || null

  signal closeRequested

  function initialize() {
    if (tabsModel.length > 0)
      return;
    tabsModel = [
      { key: "general", icon: "person", label: "General", source: generalTab },
      { key: "appearance", icon: "palette", label: "Appearance", source: appearanceTab },
      { key: "bar", icon: "crop_16_9", label: "Bar", source: barTab },
      { key: "displays", icon: "wallpaper", label: "Displays & Wallpaper", source: displaysTab },
      { key: "network", icon: "network_wifi", label: "Network & Bluetooth", source: networkTab },
      { key: "audio", icon: "volume_up", label: "Audio & Media", source: audioTab },
      { key: "notifications", icon: "notifications", label: "Notifications", source: notificationsTab },
      { key: "dashboard", icon: "dashboard", label: "Dashboard", source: dashboardTab },
      { key: "system", icon: "lock", label: "System & Lock", source: systemTab },
      { key: "about", icon: "info", label: "About", source: aboutTab }
    ];
    loadCurrentTab(false);
  }

  function selectTab(index) {
    if (index < 0 || index >= tabsModel.length || index === currentTabIndex)
      return;
    previousTabIndex = currentTabIndex;
    currentTabIndex = index;
    loadCurrentTab(true);
  }

  function loadCurrentTab(animate) {
    if (!currentTab)
      return;
    const direction = currentTabIndex >= previousTabIndex ? 1 : -1;
    if (animate) {
      tabOpacity = 0;
      tabOffset = direction * 18;
    }
    tabLoader.active = false;
    tabLoader.active = true;
    if (animate) {
      Qt.callLater(() => {
        root.tabOffset = 0;
        root.tabOpacity = 1;
      });
    }
  }

  Component.onCompleted: initialize()
  onWidthChanged: {
    if (width < 840)
      expanded = false;
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: Style.padding.small
    spacing: Style.spacing.small

    IBox {
      id: sidebar
      Layout.preferredWidth: Math.round(root.expanded ? 218 : root.iconSize + Style.padding.small * 4)
      Layout.fillHeight: true
      color: "transparent"

      Behavior on Layout.preferredWidth { IAnim {} }

      IListView {
        id: sidebarList
        anchors.fill: parent
        anchors.margins: Style.padding.small
        model: root.tabsModel
        spacing: Style.spacing.small
        clip: true

        delegate: Rectangle {
          id: tabItem
          required property int index
          required property var modelData
          width: sidebarList.width - (sidebarList.verticalScrollBarActive ? Style.spacing.small : 0)
          height: tabEntry.implicitHeight + Style.padding.small * 2
          radius: Style.rounding.small
          readonly property bool selected: index === root.currentTabIndex
          color: selected ? ThemeService.palette.mPrimary : (tabMouse.containsMouse ? Qt.alpha(ThemeService.palette.mPrimary, 0.14) : "transparent")

          Behavior on color { ICAnim {} }

          RowLayout {
            id: tabEntry
            anchors.fill: parent
            anchors.leftMargin: Style.padding.small
            anchors.rightMargin: Style.padding.small
            spacing: Style.spacing.small
            IIcon {
              icon: tabItem.modelData.icon
              color: tabItem.selected ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface
              font.pointSize: Style.font.size.large
              Layout.preferredWidth: root.iconSize
              Layout.preferredHeight: root.iconSize
            }
            IText {
              text: tabItem.modelData.label
              color: tabItem.selected ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface
              font.weight: Font.Medium
              Layout.fillWidth: true
              visible: root.expanded
              opacity: root.expanded ? 1.0 : 0.0
              Behavior on opacity { IAnim {} }
            }
          }
          MouseArea {
            id: tabMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.selectTab(tabItem.index)
          }
        }
      }
    }

    IBox {
      Layout.fillWidth: true
      Layout.fillHeight: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.padding.small
        spacing: Style.spacing.small

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.spacing.small
          IIconButton {
            icon: root.expanded ? "right_panel_close" : "left_panel_close"
            onClicked: root.expanded = !root.expanded
          }
          IDivider { orientation: "vertical"; Layout.preferredHeight: Style.widget.size - Style.padding.small * 2 }
          IText {
            Layout.fillWidth: true
            text: root.currentTab ? root.currentTab.label : "Settings"
            font.weight: Font.Medium
            font.pointSize: Style.font.size.larger
          }
          IIconButton { icon: "close"; onClicked: root.closeRequested() }
        }
        IDivider { Layout.fillWidth: true }

        Item {
          id: tabViewport
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          Loader {
            id: tabLoader
            width: parent.width
            height: parent.height
            x: root.tabOffset
            opacity: root.tabOpacity
            asynchronous: false

            Behavior on x { IAnim {} }
            Behavior on opacity { IAnim {} }

            sourceComponent: tabPageContainer
          }
        }
      }
    }
  }

  Component { id: generalTab; SettingsTabs.General {} }
  Component { id: appearanceTab; SettingsTabs.Appearance {} }
  Component { id: barTab; SettingsTabs.Bar {} }
  Component { id: displaysTab; SettingsTabs.Displays {} }
  Component { id: networkTab; SettingsTabs.Network {} }
  Component { id: audioTab; SettingsTabs.Audio {} }
  Component { id: notificationsTab; SettingsTabs.Notifications {} }
  Component { id: dashboardTab; SettingsTabs.Dashboard {} }
  Component { id: systemTab; SettingsTabs.System {} }
  Component { id: aboutTab; SettingsTabs.About {} }

  Component {
    id: tabPageContainer
    IFlickable {
      anchors.fill: parent
      anchors.margins: Style.padding.small
      contentWidth: width
      contentHeight: Math.max(height, pageLoader.item ? pageLoader.item.implicitHeight : 0)
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      Loader {
        id: pageLoader
        width: parent.width
        sourceComponent: root.currentTab ? root.currentTab.source : null
      }
    }
  }
}
