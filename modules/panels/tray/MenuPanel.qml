pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.commons
import qs.services
import qs.widgets
import ".."

BarPanel {
  id: root

  property QsMenuHandle menu
  property var trayItem: null

  readonly property real padding: Config.appearance.padding.normal
  readonly property real spacing: Config.appearance.spacing.small
  readonly property real trayWidth: 280

  function addToFavorites() {
    if (!trayItem)
      return;
    const itemName = trayItem.tooltipTitle || trayItem.name || trayItem.id || "";
    if (!itemName)
      return;
    const favorites = Settings.tray.favorites || [];
    Settings.tray.favorites = favorites.concat(itemName);
    Settings.saveImmediate();

    if (root.screen)
      root.close();
  }

  function removeFromFavorites() {
    if (!trayItem)
      return;
    const itemName = trayItem.tooltipTitle || trayItem.name || trayItem.id || "";
    if (!itemName)
      return;
    const favorites = Settings.tray.favorites || [];
    Settings.tray.favorites = favorites.filter(f => f !== itemName);
    Settings.saveImmediate();

    if (root.screen)
      root.close();
  }

  contentComponent: Item {
    id: content

    property list<var> activeSubMenuItems: []

    Connections {
      target: root
      function onOpened() {
        content.activeSubMenuItems = [];
      }
    }

    implicitWidth: root.trayWidth
    implicitHeight: {
      if (activeSubMenuItems.length > 0) {
        const subFlick = inPlaceSubMenuLoader.item;
        const subHeight = subFlick?.contentHeight || 0;
        const maxH = (root.screen ? root.screen.height : Screen.height) * 0.9;
        return Math.min(maxH, subHeight + (root.padding * 2));
      }

      const mainHeight = mainFlickable.contentHeight;
      const maxH = (root.screen ? root.screen.height : Screen.height) * 0.9;
      return Math.min(maxH, mainHeight + (root.padding * 2));
    }

    QsMenuOpener {
      id: opener
      menu: root.menu
    }

    Component {
      id: subMenuComponent

      Flickable {
        id: subMenuFlickable
        anchors.fill: parent
        contentHeight: subMenuColumnLayout.implicitHeight
        interactive: true

        ColumnLayout {
          id: subMenuColumnLayout
          width: subMenuFlickable.width
          spacing: 0

          QsMenuOpener {
            id: subMenuOpener
            menu: content.activeSubMenuItems[content.activeSubMenuItems.length - 1] || null
          }

          Rectangle {
            id: backEntry
            visible: content.activeSubMenuItems.length > 0
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: visible ? 28 : 0
            color: ThemeService.palette.mSurface

            Rectangle {
              anchors.fill: parent
              anchors.leftMargin: root.padding
              anchors.rightMargin: root.padding
              anchors.horizontalCenter: parent.horizontalCenter
              width: parent.width - (root.padding * 2)
              color: backMouseArea.containsMouse ? ThemeService.palette.mSurfaceContainer : ThemeService.palette.mSurface
              radius: Settings.appearance.cornerRadius

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.padding
                anchors.rightMargin: root.padding
                spacing: root.spacing

                IIcon {
                  icon: "chevron_left"
                  pointSize: Config.appearance.font.size.small
                  color: backMouseArea.containsMouse ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurface
                }

                IText {
                  Layout.fillWidth: true
                  text: "Back"
                  pointSize: Config.appearance.font.size.small
                  color: backMouseArea.containsMouse ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurface
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                id: backMouseArea
                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                  if (content.activeSubMenuItems.length > 0) {
                    content.activeSubMenuItems.pop();
                  }
                }
              }
            }
          }

          Rectangle {
            visible: content.activeSubMenuItems.length > 0
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: visible ? 8 : 0
            color: ThemeService.palette.mSurface

            IDivider {
              anchors.centerIn: parent
              width: parent.width - (root.padding * 2)
            }
          }

          Repeater {
            model: subMenuOpener.children ? [...subMenuOpener.children.values] : []

            delegate: Rectangle {
              id: subEntry
              required property var modelData

              Layout.preferredWidth: parent.width
              Layout.preferredHeight: modelData?.isSeparator ? 8 : 28
              color: ThemeService.palette.mSurface

              IDivider {
                anchors.centerIn: parent
                width: parent.width - (root.padding * 2)
                visible: subEntry.modelData?.isSeparator
              }

              Rectangle {
                anchors.fill: parent
                anchors.leftMargin: root.padding
                anchors.rightMargin: root.padding
                radius: Settings.appearance.cornerRadius
                visible: !subEntry.modelData?.isSeparator
                color: subMouseArea.containsMouse ? ThemeService.palette.mSurfaceContainer : ThemeService.palette.mSurface

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: root.padding
                  anchors.rightMargin: root.padding
                  spacing: root.spacing

                  IText {
                    Layout.fillWidth: true
                    text: subEntry.modelData?.text !== "" ? subEntry.modelData.text.replace(/[\n\r]+/g, " ") : "..."
                    pointSize: Config.appearance.font.size.small
                    color: (subEntry.modelData?.enabled ?? true) ? (subMouseArea.containsMouse ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurface) : ThemeService.palette.mPrimary
                    elide: Text.ElideRight
                  }

                  IconImage {
                    implicitSize: root.padding
                    source: subEntry.modelData?.icon ?? ""
                    visible: !!subEntry.modelData?.icon
                    backer.fillMode: Image.PreserveAspectFit

                    layer.enabled: Settings.tray.colorize
                    layer.effect: ShaderEffect {
                      property color targetColor: ThemeService.palette.mSecondary
                      property real colorizeMode: 1.0
                      fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/shaders/qsb/appicon_colorize.frag.qsb")
                    }
                  }

                  IIcon {
                    icon: subEntry.modelData?.hasChildren ? "menu" : ""
                    pointSize: Config.appearance.font.size.small
                    visible: subEntry.modelData?.hasChildren
                    Layout.rightMargin: root.padding
                    color: subMouseArea.containsMouse ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurface
                  }
                }

                MouseArea {
                  id: subMouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  enabled: subEntry.modelData?.enabled && !subEntry.modelData?.isSeparator

                  onClicked: {
                    if (subEntry.modelData?.isSeparator)
                      return;
                    if (subEntry.modelData.hasChildren) {
                      content.activeSubMenuItems.push(subEntry.modelData);
                    } else {
                      subEntry.modelData.triggered();
                      root.close();
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    RowLayout {
      id: rowLayout
      anchors.fill: parent
      anchors.topMargin: root.padding
      spacing: 0

      Loader {
        id: inPlaceSubMenuLoader
        Layout.preferredWidth: content.activeSubMenuItems.length > 0 ? root.trayWidth : 0
        Layout.fillHeight: true
        visible: content.activeSubMenuItems.length > 0
        sourceComponent: subMenuComponent
      }

      Flickable {
        id: mainFlickable
        Layout.preferredWidth: content.activeSubMenuItems.length > 0 ? 0 : root.trayWidth
        Layout.fillHeight: true
        contentHeight: mainColumnLayout.implicitHeight
        visible: content.activeSubMenuItems.length === 0

        ColumnLayout {
          id: mainColumnLayout
          width: mainFlickable.width
          spacing: 0

          Repeater {
            model: opener.children ? [...opener.children.values] : []

            delegate: Rectangle {
              id: entry
              required property var modelData

              Layout.preferredWidth: parent.width
              Layout.preferredHeight: modelData?.isSeparator ? 8 : 28
              color: ThemeService.palette.mSurface

              IDivider {
                anchors.centerIn: parent
                width: parent.width - root.padding
                visible: entry.modelData?.isSeparator
              }

              Rectangle {
                anchors.fill: parent
                anchors.leftMargin: root.padding
                anchors.rightMargin: root.padding
                radius: Settings.appearance.cornerRadius
                visible: !entry.modelData?.isSeparator
                color: mouseArea.containsMouse ? ThemeService.palette.mSurfaceContainer : ThemeService.palette.mSurface

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: root.padding
                  anchors.rightMargin: root.padding
                  spacing: root.spacing

                  IText {
                    Layout.fillWidth: true
                    text: entry.modelData?.text !== "" ? entry.modelData.text.replace(/[\n\r]+/g, " ") : "..."
                    pointSize: Config.appearance.font.size.small
                    color: (entry.modelData?.enabled ?? true) ? (mouseArea.containsMouse ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurface) : ThemeService.palette.mOnSurfaceVariant
                    elide: Text.ElideRight
                  }

                  IconImage {
                    implicitSize: root.padding
                    source: entry.modelData?.icon ?? ""
                    visible: !!entry.modelData?.icon
                    backer.fillMode: Image.PreserveAspectFit

                    layer.enabled: Settings.tray.colorize
                    layer.effect: ShaderEffect {
                      property color targetColor: ThemeService.palette.mSecondary
                      property real colorizeMode: 1.0
                      fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/shaders/qsb/appicon_colorize.frag.qsb")
                    }
                  }

                  IIcon {
                    icon: entry.modelData?.hasChildren ? "menu" : ""
                    pointSize: Config.appearance.font.size.small
                    visible: entry.modelData?.hasChildren
                    Layout.rightMargin: root.padding
                    color: mouseArea.containsMouse ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurface
                  }
                }

                MouseArea {
                  id: mouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  enabled: entry.modelData?.enabled && !entry.modelData?.isSeparator

                  onClicked: {
                    if (entry.modelData?.isSeparator)
                      return;
                    if (entry.modelData.hasChildren) {
                      content.activeSubMenuItems.push(entry.modelData);
                    } else {
                      entry.modelData.triggered();
                      root.close();
                    }
                  }
                }
              }
            }
          }

          Rectangle {
            visible: root.trayItem
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: visible ? 8 : 0
            color: ThemeService.palette.mSurface

            IDivider {
              anchors.centerIn: parent
              width: parent.width - root.padding
            }
          }

          Rectangle {
            id: addToFavoriteEntry
            visible: root.trayItem
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: visible ? 28 : 0
            color: ThemeService.palette.mSurface

            readonly property bool isFavorite: {
              const itemName = root.trayItem.tooltipTitle || root.trayItem.name || root.trayItem.id || "";
              if (!itemName)
                return false;
              const favorites = Settings.tray.favorites || [];
              return favorites.indexOf(itemName) !== -1;
            }

            Rectangle {
              anchors.fill: parent
              anchors.leftMargin: root.padding
              anchors.rightMargin: root.padding
              radius: Settings.appearance.cornerRadius
              color: addToFavoriteMouseArea.containsMouse ? Qt.alpha(ThemeService.palette.mPrimary, 0.2) : Qt.alpha(ThemeService.palette.mPrimary, 0.08)
              border.color: Qt.alpha(ThemeService.palette.mPrimary, addToFavoriteMouseArea.containsMouse ? 0.4 : 0.2)
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.padding
                anchors.rightMargin: root.padding
                spacing: root.spacing

                IIcon {
                  icon: addToFavoriteEntry.isFavorite ? "keep_off" : "keep"
                  pointSize: Config.appearance.font.size.small
                  verticalAlignment: Text.AlignVCenter
                  color: ThemeService.palette.mPrimary
                }

                IText {
                  Layout.fillWidth: true
                  text: addToFavoriteEntry.isFavorite ? "Unpin application" : "Pin application"
                  pointSize: Config.appearance.font.size.small
                  verticalAlignment: Text.AlignVCenter
                  elide: Text.ElideRight
                  color: ThemeService.palette.mPrimary
                }
              }

              MouseArea {
                id: addToFavoriteMouseArea
                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                  if (addToFavoriteEntry.isFavorite) {
                    root.removeFromFavorites();
                  } else {
                    root.addToFavorites();
                  }
                  root.close();
                }
              }
            }
          }
        }
      }
    }
  }
}
