import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.commons
import qs.services
import qs.widgets
import "../helpers/fuzzysort.js" as Fuzzysort

RowLayout {
  id: root

  property real minimumWidth: 280
  property real popupHeight: 180

  property string label: ""
  property string description: ""
  property ListModel model: ListModel {}
  property string currentKey: ""
  property string placeholder: ""
  property string searchPlaceholder: "Search..."
  property Component delegate: null

  readonly property real preferredHeight: Style.appearance.widget.size * 1.1

  signal selected(string key)

  spacing: Style.appearance.spacing.small
  Layout.fillWidth: true

  property ListModel filteredModel: ListModel {}
  property string searchText: ""

  function findIndexByKey(key) {
    for (var i = 0; i < root.model.count; i++) {
      if (root.model.get(i).key === key)
        return i;
    }
    return -1;
  }

  function findIndexByKeyInFiltered(key) {
    for (var i = 0; i < root.filteredModel.count; i++) {
      if (root.filteredModel.get(i).key === key)
        return i;
    }
    return -1;
  }

  function filterModel() {
    filteredModel.clear();

    if (!root.model || root.model.count === undefined || root.model.count === 0)
      return;
    if (searchText.trim() === "") {
      for (var i = 0; i < root.model.count; i++)
        filteredModel.append(root.model.get(i));
    } else {
      var items = [];
      for (var j = 0; j < root.model.count; j++)
        items.push(root.model.get(j));

      if (typeof Fuzzysort !== "undefined") {
        var fuzzyResults = Fuzzysort.go(searchText, items, {
          key: "name",
          threshold: -1000,
          limit: 50
        });

        for (var k = 0; k < fuzzyResults.length; k++)
          filteredModel.append(fuzzyResults[k].obj);
      } else {
        var searchLower = searchText.toLowerCase();
        for (var m = 0; m < items.length; m++) {
          var item = items[m];
          if (item.name.toLowerCase().includes(searchLower))
            filteredModel.append(item);
        }
      }
    }
  }

  onSearchTextChanged: filterModel()
  onModelChanged: filterModel()

  ILabel {
    label: root.label
    description: root.description
  }

  Item {
    Layout.fillWidth: true
  }

  ComboBox {
    id: combo

    Layout.minimumWidth: root.minimumWidth
    Layout.preferredHeight: root.preferredHeight
    model: root.filteredModel
    currentIndex: root.findIndexByKeyInFiltered(root.currentKey)

    onActivated: {
      if (combo.currentIndex >= 0 && combo.currentIndex < filteredModel.count)
        root.selected(filteredModel.get(combo.currentIndex).key);
    }

    background: Rectangle {
      implicitWidth: Style.appearance.widget.size * 3.75
      implicitHeight: preferredHeight
      color: ThemeService.palette.mSurfaceVariant
      border.color: combo.activeFocus ? ThemeService.palette.mSecondary : Qt.alpha(ThemeService.palette.mOutline, 0.2)
      border.width: 1
      radius: Settings.appearance.cornerRadius

      Behavior on border.color {
        ICAnim {}
      }
    }

    contentItem: IText {
      leftPadding: Style.appearance.padding.normal
      rightPadding: combo.indicator.width + Style.appearance.padding.normal
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      color: combo.currentIndex >= 0 && combo.currentIndex < filteredModel.count ? ThemeService.palette.mOnSurface : ThemeService.palette.mOnSurfaceVariant
      text: combo.currentIndex >= 0 && combo.currentIndex < filteredModel.count ? filteredModel.get(combo.currentIndex).name : root.placeholder
    }

    indicator: IIcon {
      x: combo.width - width - Style.appearance.padding.normal
      y: combo.topPadding + (combo.availableHeight - height) / 2
      icon: "arrow_drop_down"
    }

    popup: Popup {
      y: combo.height
      width: combo.width
      height: root.popupHeight + 60
      padding: Style.appearance.padding.normal

      onOpened: VisibilityService.willOpenPopup(root)
      onClosed: VisibilityService.willClosePopup(root)

      contentItem: ColumnLayout {
        spacing: Style.appearance.spacing.small

        ITextInput {
          id: searchInput
          inputIconName: "search"
          Layout.fillWidth: true
          placeholderText: root.searchPlaceholder
          text: root.searchText
          onTextChanged: root.searchText = text
          fontSize: Style.appearance.font.size.small
        }

        IListView {
          id: listView
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: combo.popup.visible ? filteredModel : null
          clip: true

          delegate: root.delegate ? root.delegate : defaultDelegate

          Component {
            id: defaultDelegate

            ItemDelegate {
              id: delegateRoot
              width: listView.width
              hoverEnabled: true
              highlighted: ListView.view.currentIndex === index

              onHoveredChanged: {
                if (hovered)
                  ListView.view.currentIndex = index;
              }

              onClicked: {
                root.selected(filteredModel.get(index).key);
                combo.currentIndex = root.findIndexByKeyInFiltered(filteredModel.get(index).key);
                combo.popup.close();
              }

              contentItem: RowLayout {
                width: parent.width
                spacing: Style.appearance.padding.normal

                IText {
                  text: name
                  color: highlighted ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface
                  verticalAlignment: Text.AlignVCenter
                  elide: Text.ElideRight
                  Layout.fillWidth: true

                  Behavior on color {
                    ICAnim {}
                  }
                }

                RowLayout {
                  spacing: Style.appearance.spacing.small
                  Layout.alignment: Qt.AlignRight

                  Repeater {
                    model: typeof badgeLocations !== "undefined" ? badgeLocations : []

                    delegate: Item {
                      width: Style.appearance.widget.size * 0.7
                      height: Style.appearance.widget.size * 0.7

                      IText {
                        anchors.centerIn: parent
                        text: modelData
                        color: highlighted ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface
                      }
                    }
                  }
                }
              }

              background: Rectangle {
                width: listView.width
                color: highlighted ? ThemeService.palette.mPrimary : "transparent"
                radius: Settings.appearance.cornerRadius

                Behavior on color {
                  ICAnim {}
                }
              }
            }
          }
        }
      }

      background: Rectangle {
        color: ThemeService.palette.mSurfaceVariant
        border.color: Qt.alpha(ThemeService.palette.mOutline, 0.2)
        border.width: 1
        radius: Settings.appearance.cornerRadius
      }
    }

    Connections {
      target: root
      function onCurrentKeyChanged() {
        combo.currentIndex = root.findIndexByKeyInFiltered(currentKey);
      }
    }

    Connections {
      target: combo.popup
      function onVisibleChanged() {
        if (combo.popup.visible) {
          root.filterModel();
          Qt.callLater(() => {
            if (searchInput && searchInput.inputItem)
              searchInput.inputItem.forceActiveFocus();
          });
        }
      }
    }
  }
}
