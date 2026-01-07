import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.services

Rectangle {
  id: root

  // Public properties
  property string text: ""
  property string icon: ""
  property color backgroundColor: ThemeService.palette.mPrimary
  property color textColor: ThemeService.palette.mOnPrimary
  property color hoverColor: ThemeService.palette.mPrimary
  property bool enabled: true
  property real fontSize: Style.appearance.font.size.small
  property int fontWeight: Font.DemiBold
  property real iconSize: Style.appearance.font.size.large
  property bool outlined: false
  property int horizontalAlignment: Qt.AlignHCenter

  // Signals
  signal clicked
  signal rightClicked
  signal middleClicked
  signal entered
  signal exited

  // Internal properties
  property bool hovered: false

  // Dimensions
  implicitWidth: contentRow.implicitWidth + (Style.appearance.padding.large * 2)
  implicitHeight: Math.max(Style.appearance.widget.size, contentRow.implicitHeight + (Style.appearance.padding.small))

  // Appearance
  radius: Settings.appearance.cornerRadius
  color: {
    if (!enabled)
      return outlined ? "transparent" : Qt.lighter(ThemeService.palette.mSurfaceVariant, 1.2);
    if (hovered)
      return hoverColor;
    return outlined ? "transparent" : backgroundColor;
  }

  border.width: outlined ? 2 : 0
  border.color: {
    if (!enabled)
      return Qt.alpha(ThemeService.palette.mOutline, 0.4);
    if (hovered)
      return backgroundColor;
    return outlined ? backgroundColor : "transparent";
  }

  opacity: enabled ? 1.0 : 0.6

  Behavior on color {
    ICAnim {}
  }

  Behavior on border.color {
    ICAnim {}
  }

  // Content
  RowLayout {
    id: contentRow
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: root.horizontalAlignment === Qt.AlignLeft ? parent.left : undefined
    anchors.horizontalCenter: root.horizontalAlignment === Qt.AlignHCenter ? parent.horizontalCenter : undefined
    anchors.leftMargin: root.horizontalAlignment === Qt.AlignLeft ? Style.appearance.padding.large : 0
    spacing: Style.appearance.spacing.small

    // Icon (optional)
    IIcon {
      Layout.alignment: Qt.AlignVCenter
      visible: root.icon !== ""
      icon: root.icon
      pointSize: root.iconSize
      color: {
        if (!root.enabled)
          return ThemeService.palette.mOnSurfaceVariant;
        if (root.outlined) {
          if (root.hovered)
            return root.textColor;
          return root.backgroundColor;
        }
        return root.textColor;
      }

      Behavior on color {
        ICAnim {}
      }
    }

    // Text
    IText {
      Layout.alignment: Qt.AlignVCenter
      visible: root.text !== ""
      text: root.text
      pointSize: root.fontSize
      font.weight: root.fontWeight
      color: {
        if (!root.enabled)
          return ThemeService.palette.mOnSurfaceVariant;
        if (root.outlined) {
          if (root.hovered)
            return root.textColor;
          return root.backgroundColor;
        }
        return root.textColor;
      }

      Behavior on color {
        ICAnim {}
      }
    }
  }

  // Mouse interaction
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    enabled: root.enabled
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    onEntered: {
      root.hovered = true;
      root.entered();
    }

    onExited: {
      root.hovered = false;
      root.exited();
    }

    onPressed: mouse => {
      if (mouse.button === Qt.LeftButton) {
        root.clicked();
      } else if (mouse.button == Qt.RightButton) {
        root.rightClicked();
      } else if (mouse.button == Qt.MiddleButton) {
        root.middleClicked();
      }
    }

    onCanceled: {
      root.hovered = false;
    }
  }
}
