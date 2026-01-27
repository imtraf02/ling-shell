import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Rectangle {
  id: root

  // Public properties
  property string text: ""
  property string icon: ""
  property color backgroundColor: ThemeService.palette.mPrimary
  property color textColor: ThemeService.palette.mOnPrimary
  property color hoverColor: Qt.lighter(backgroundColor, 1.1)
  property bool enabled: true
  property real fontSize: Style.font.size.small
  property int fontWeight: Font.Medium
  property real iconSize: Style.font.size.large
  property bool outlined: false
  property int horizontalAlignment: Qt.AlignHCenter

  // Signals
  signal clicked
  signal rightClicked
  signal middleClicked
  signal entered
  signal exited

  // Internal Logic
  readonly property bool hovered: mouseArea.containsMouse

  readonly property color _computedBackgroundColor: {
    if (!enabled)
      return outlined ? "transparent" : Qt.lighter(ThemeService.palette.mSurfaceVariant, 1.2);
    if (hovered)
      return hoverColor;
    return outlined ? "transparent" : backgroundColor;
  }

  readonly property color _computedBorderColor: {
    if (!enabled)
      return Qt.alpha(ThemeService.palette.mOutline, 0.4);
    if (hovered)
      return backgroundColor;
    return outlined ? backgroundColor : "transparent";
  }

  readonly property color _computedContentColor: {
    if (!enabled)
      return ThemeService.palette.mOnSurfaceVariant;
    if (outlined) {
      if (hovered)
        return textColor;
      return backgroundColor;
    }
    return textColor;
  }

  // Dimensions
  implicitWidth: contentRow.implicitWidth + (Style.padding.large * 2)
  implicitHeight: Math.max(Style.widget.size, contentRow.implicitHeight + (Style.padding.small))

  // Appearance
  radius: Style.rounding.small
  color: _computedBackgroundColor
  border.width: outlined ? 2 : 0
  border.color: _computedBorderColor

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
    anchors.leftMargin: root.horizontalAlignment === Qt.AlignLeft ? Style.padding.large : 0
    spacing: Style.spacing.small

    // Icon (optional)
    IIcon {
      Layout.alignment: Qt.AlignVCenter
      visible: root.icon !== ""
      icon: root.icon
      font.pointSize: root.iconSize
      color: root._computedContentColor

      Behavior on color {
        ICAnim {}
      }
    }

    // Text
    IText {
      Layout.alignment: Qt.AlignVCenter
      visible: root.text !== ""
      text: root.text
      font.pointSize: root.fontSize
      font.weight: root.fontWeight
      color: root._computedContentColor

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

    onEntered: root.entered()
    onExited: root.exited()

    onPressed: mouse => {
      if (mouse.button === Qt.LeftButton) {
        root.clicked();
      } else if (mouse.button == Qt.RightButton) {
        root.rightClicked();
      } else if (mouse.button == Qt.MiddleButton) {
        root.middleClicked();
      }
    }
  }
}
