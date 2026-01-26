pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.widgets
import qs.services

Item {
  id: root

  property int requestedTab: 0

  property int currentTabIndex: 0
  property var tabsModel: []
  property bool expanded: true

  readonly property int iconSize: Math.max(1, Math.round(Style.widget.size * 0.8))

  signal closeRequested

  function initialize() {
    root.tabsModel = [
      {
        id: Panel.Tab.About,
        icon: "info",
        label: "About"
      },
      {
        id: Panel.Tab.Bar,
        icon: "crop_16_9",
        label: "Bar"
      },
      {
        id: Panel.Tab.Personalization,
        icon: "palette",
        label: "Personalization"
      },
    ];
    root.currentTabIndex = requestedTab;
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: Style.padding.small
    spacing: Style.spacing.small

    IBox {
      id: sidebar
      Layout.preferredWidth: Math.round(root.expanded ? 200 : root.iconSize + Style.padding.small * 2 + Style.padding.small * 2)
      Layout.fillHeight: true
      Layout.alignment: Qt.AlignTop
      color: "transparent"

      Behavior on Layout.preferredWidth {
        IAnim {}
      }

      ColumnLayout {
        id: sidebarColumnLayout
        anchors.fill: parent
        anchors.margins: Style.padding.small
        spacing: Style.spacing.small

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.bottomMargin: Style.padding.small
          IListView {
            id: sidebarList
            model: root.tabsModel
            anchors.fill: parent
            spacing: Style.spacing.small
            currentIndex: root.currentTabIndex
            delegate: Rectangle {
              id: tabItem
              required property int index
              required property var modelData
              width: sidebarList.width - (sidebarList.verticalScrollBarActive ? Style.spacing.small : 0)
              height: tabEntryRow.implicitHeight + Style.padding.small * 2
              radius: Style.rounding.small
              color: selected ? ThemeService.palette.mPrimary : (tabItem.hovering ? ThemeService.palette.mPrimary : "transparent")
              readonly property bool selected: index === root.currentTabIndex
              property bool hovering: false
              property color tabTextColor: selected ? ThemeService.palette.mOnPrimary : (tabItem.hovering ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface)

              Behavior on color {
                ICAnim {}
              }

              RowLayout {
                id: tabEntryRow
                anchors.fill: parent
                anchors.leftMargin: Style.padding.small
                anchors.rightMargin: Style.padding.small
                spacing: Style.spacing.small
                IIcon {
                  icon: tabItem.modelData.icon
                  color: tabTextColor
                  font.pointSize: Style.font.size.large
                  Layout.alignment: Qt.AlignVCenter
                  Layout.preferredWidth: root.iconSize
                  Layout.preferredHeight: root.iconSize
                }
                IText {
                  text: tabItem.modelData.label
                  color: tabTextColor
                  font.pointSize: Style.font.size.smaller
                  font.weight: Font.Medium
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  visible: root.expanded
                  opacity: root.expanded ? 1.0 : 0.0
                  Behavior on opacity {
                    IAnim {}
                  }
                }
              }
              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                  tabItem.hovering = true;
                }
                onExited: {
                  tabItem.hovering = false;
                }
                onCanceled: {
                  tabItem.hovering = false;
                }
                onClicked: {
                  root.currentTabIndex = tabItem.index;
                }
              }
            }
          }
        }
      }
    }

    IBox {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.alignment: Qt.AlignTop

      ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: Style.padding.small
        spacing: Style.spacing.small

        RowLayout {
          id: headerRow
          Layout.fillWidth: true
          spacing: Style.spacing.small

          Rectangle {
            id: sidebarToggle
            Layout.preferredWidth: root.iconSize + Style.padding.small * 2
            Layout.preferredHeight: root.iconSize + Style.padding.small * 2
            radius: Style.rounding.small
            color: toggleMouseArea.containsMouse ? ThemeService.palette.mPrimary : "transparent"

            Behavior on color {
              ICAnim {}
            }

            IIcon {
              anchors.centerIn: parent
              icon: root.expanded ? "right_panel_close" : "left_panel_close"
              color: toggleMouseArea.containsMouse ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface
              font.pointSize: Style.font.size.large
              width: root.iconSize
              height: root.iconSize
            }

            MouseArea {
              id: toggleMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.expanded = !root.expanded;
              }
            }
          }

          IDivider {
            orientation: "vertical"
            Layout.preferredHeight: sidebarToggle.height - Style.padding.small * 2
          }

          IText {
            text: root.tabsModel[root.currentTabIndex]?.label ? root.tabsModel[root.currentTabIndex].label : ""
            font.weight: Font.Medium
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
          }

          IIconButton {
            icon: "close"
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.closeRequested()
          }
        }

        IDivider {
          Layout.fillWidth: true
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          color: "transparent"
        }
      }
    }
  }
}
