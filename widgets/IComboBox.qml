pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.services

RowLayout {
  id: root

  property real minimumWidth: 200
  property real popupHeight: 180

  property string label: ""
  property string description: ""
  property var model
  property string currentKey: ""
  property string placeholder: ""

  readonly property real preferredHeight: Style.widget.size * 1.1

  signal selected(string key)

  spacing: Style.spacing.small
  Layout.fillWidth: true

  function itemCount() {
    if (!root.model)
      return 0;
    if (typeof root.model.count === "number")
      return root.model.count;
    if (Array.isArray(root.model))
      return root.model.length;
    return 0;
  }

  function getItem(index) {
    if (!root.model)
      return null;
    if (typeof root.model.get === "function")
      return root.model.get(index);
    if (Array.isArray(root.model))
      return root.model[index];
    return null;
  }

  function findIndexByKey(key) {
    for (var i = 0; i < itemCount(); i++) {
      var item = getItem(i);
      if (item && item.key === key)
        return i;
    }
    return -1;
  }

  ILabel {
    label: root.label
    description: root.description
  }

  ComboBox {
    id: combo

    Layout.minimumWidth: root.minimumWidth
    Layout.preferredHeight: root.preferredHeight
    model: model
    currentIndex: root.findIndexByKey(root.currentKey)

    onActivated: {
      var item = root.getItem(combo.currentIndex);
      if (item && item.key !== undefined)
        root.selected(item.key);
    }

    background: Rectangle {
      implicitWidth: Style.widget.size * 3.75
      implicitHeight: root.preferredHeight
      color: ThemeService.palette.mSurfaceVariant
      border.color: Qt.alpha(combo.activeFocus ? ThemeService.palette.mSecondary : ThemeService.palette.mOutline, 0.2)
      border.width: 1
      radius: Style.rounding.small

      Behavior on border.color {
        ICAnim {}
      }
    }

    contentItem: IText {
      leftPadding: Style.padding.normal
      rightPadding: combo.indicator.width + Style.padding.normal
      font.pointSize: Style.font.size.smaller
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      color: (combo.currentIndex >= 0 && combo.currentIndex < root.itemCount()) ? ThemeService.palette.mOnSurface : ThemeService.palette.mOnSurfaceVariant
      text: (combo.currentIndex >= 0 && combo.currentIndex < root.itemCount()) ? (root.getItem(combo.currentIndex) ? root.getItem(combo.currentIndex).name : root.placeholder) : root.placeholder
    }

    indicator: IIcon {
      x: combo.width - width - Style.padding.normal
      y: combo.topPadding + (combo.availableHeight - height) / 2
      icon: "arrow_drop_down"
      font.pointSize: Style.font.size.large
    }

    popup: Popup {
      y: combo.height
      implicitWidth: combo.width
      implicitHeight: Math.min(root.popupHeight, contentItem.implicitHeight + Style.padding.normal * 2)
      padding: Style.padding.normal

      contentItem: IListView {
        model: combo.popup.visible ? root.model : null
        implicitHeight: contentHeight
        spacing: root.spacing
        clip: true

        delegate: ItemDelegate {
          id: delegateItem

          required property int index
          required property var modelData

          property ComboBox parentComboBox: combo
          property int itemIndex: index

          width: parentComboBox.width
          hoverEnabled: true
          highlighted: ListView.view ? ListView.view.currentIndex === itemIndex : false

          onHoveredChanged: {
            if (hovered && ListView.view)
              ListView.view.currentIndex = itemIndex;
          }

          onClicked: {
            var item = root.getItem(itemIndex);
            if (item && item.key !== undefined) {
              root.selected(item.key);
              parentComboBox.currentIndex = itemIndex;
              parentComboBox.popup.close();
            }
          }

          background: Rectangle {
            width: delegateItem.parentComboBox.width - Style.padding.normal * 2
            color: delegateItem.highlighted ? ThemeService.palette.mPrimary : "transparent"
            radius: Style.rounding.small

            Behavior on color {
              ICAnim {}
            }
          }

          contentItem: IText {
            text: {
              var item = root.getItem(delegateItem.index);
              return item && item.name ? item.name : "";
            }
            font.pointSize: Style.font.size.smaller
            color: delegateItem.highlighted ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight

            Behavior on color {
              ICAnim {}
            }
          }
        }
      }

      background: Rectangle {
        color: ThemeService.palette.mSurfaceVariant
        border.color: Qt.alpha(ThemeService.palette.mOutline, 0.2)
        border.width: 1
        radius: Style.rounding.small
      }
    }

    Connections {
      target: root

      function onCurrentKeyChanged() {
        combo.currentIndex = root.findIndexByKey(root.currentKey);
      }
    }
  }
}
