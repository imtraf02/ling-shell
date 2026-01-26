import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

ColumnLayout {
  id: root
  property string icon: "skull"
  property string title: "Title"
  property bool active: false
  property bool enable: true
  property bool showDetails: false
  signal clicked
  signal detailsClicked
  spacing: Style.padding.small

  RowLayout {
    id: content
    Layout.fillWidth: true
    Layout.preferredHeight: 48
    spacing: 0

    Rectangle {
      id: iconSection
      Layout.fillWidth: !root.showDetails
      Layout.preferredWidth: root.showDetails ? parent.width / 2 : parent.width
      Layout.fillHeight: true

      topLeftRadius: Settings.appearance.cornerRadius
      bottomLeftRadius: Settings.appearance.cornerRadius
      topRightRadius: root.showDetails ? 0 : Settings.appearance.cornerRadius
      bottomRightRadius: root.showDetails ? 0 : Settings.appearance.cornerRadius

      color: iconMouseArea.containsMouse && root.enable ? (root.active ? ThemeService.palette.mPrimaryContainer : ThemeService.palette.mSurfaceContainerHigh) : (root.active ? ThemeService.palette.mPrimary : ThemeService.palette.mSurfaceContainer)

      border.color: Qt.alpha(ThemeService.palette.mPrimary, 0.4)
      border.width: 1

      Behavior on color {
        ICAnim {}
      }

      IIcon {
        anchors.centerIn: parent
        icon: root.icon

        color: iconMouseArea.containsMouse && root.enable ? (root.active ? ThemeService.palette.mOnPrimaryContainer : ThemeService.palette.mOnSurface) : (root.active ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface)

        Behavior on color {
          ICAnim {}
        }
      }

      MouseArea {
        id: iconMouseArea
        anchors.fill: parent
        enabled: root.enable
        cursorShape: root.enable ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true
        onClicked: root.clicked()
        onPressed: iconSection.scale = 0.95
        onReleased: iconSection.scale = 1.0
      }

      Behavior on scale {
        IAnim {}
      }
    }

    Rectangle {
      id: chevronSection
      visible: root.showDetails
      Layout.fillWidth: true
      Layout.preferredWidth: root.showDetails ? parent.width / 2 : 0
      Layout.fillHeight: true

      topRightRadius: Settings.appearance.cornerRadius
      bottomRightRadius: Settings.appearance.cornerRadius
      topLeftRadius: 0
      bottomLeftRadius: 0

      color: chevronMouseArea.containsMouse && root.enable ? (root.active ? ThemeService.palette.mPrimaryContainer : ThemeService.palette.mSurfaceContainerHigh) : (root.active ? ThemeService.palette.mPrimary : ThemeService.palette.mSurfaceContainer)

      border.color: Qt.alpha(ThemeService.palette.mPrimary, 0.4)
      border.width: 1

      Behavior on color {
        ICAnim {}
      }

      IIcon {
        anchors.centerIn: parent
        icon: "chevron_right"

        color: chevronMouseArea.containsMouse && root.enable ? (root.active ? ThemeService.palette.mOnPrimaryContainer : ThemeService.palette.mOnSurface) : (root.active ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface)

        Behavior on color {
          ICAnim {}
        }
      }

      MouseArea {
        id: chevronMouseArea
        anchors.fill: parent
        enabled: root.enable
        cursorShape: root.enable ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true
        onClicked: root.detailsClicked()
        onPressed: chevronSection.scale = 0.95
        onReleased: chevronSection.scale = 1.0
      }

      Behavior on scale {
        IAnim {}
      }
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: titleText.implicitHeight
    IText {
      id: titleText
      text: root.title
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      maximumLineCount: 1
      elide: Text.ElideRight
    }
  }
}
