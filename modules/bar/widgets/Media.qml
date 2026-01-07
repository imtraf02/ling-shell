pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.commons
import qs.services
import qs.widgets
import qs.widgets.audiospectrum

Item {
  id: root

  property ShellScreen screen
  property string placeholderText: "No active player"

  readonly property bool hasActivePlayer: MediaService.currentPlayer !== null
  readonly property real padding: Style.appearance.padding.normal
  readonly property real spacing: Style.appearance.spacing.small
  readonly property real maxWidth: 280
  readonly property real buttonSize: 28

  implicitWidth: Math.min(calculateContentWidth(), maxWidth)
  implicitHeight: Style.bar.innerHeight

  Behavior on implicitWidth {
    IAnim {}
  }

  function calculateContentWidth() {
    let buttonsWidth = root.buttonSize;
    if (MediaService.canGoPrevious) {
      buttonsWidth += root.buttonSize;
    }
    if (MediaService.canGoNext) {
      buttonsWidth += root.buttonSize;
    }
    const titleWidth = fullTitleMetrics.contentWidth;
    return root.padding * 2 + buttonsWidth + root.spacing + titleWidth;
  }

  function getTitle() {
    return MediaService.trackTitle + (MediaService.trackArtist !== "" ? ` - ${MediaService.trackArtist}` : "");
  }

  IText {
    id: fullTitleMetrics
    visible: false
    text: root.hasActivePlayer ? root.getTitle() : root.placeholderText
    pointSize: Style.appearance.font.size.small
  }

  Rectangle {
    id: mediaMini
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: Style.bar.innerHeight
    color: ThemeService.palette.mSurfaceContainer
    radius: Settings.appearance.cornerRadius

    Item {
      id: mainContainer
      anchors.fill: parent
      anchors.leftMargin: root.padding
      anchors.rightMargin: root.padding
      clip: true

      Loader {
        anchors.centerIn: parent
        active: MediaService.isPlaying
        z: 0
        sourceComponent: ILinearSpectrum {
          width: mainContainer.width - root.spacing
          height: 20
          values: CavaService.values
          fillColor: ThemeService.palette.mPrimary
          opacity: 0.4
        }
      }

      RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: root.spacing
        z: 1

        RowLayout {
          Layout.alignment: Qt.AlignVCenter
          spacing: 0

          MediaControlButton {
            visible: MediaService.canGoPrevious
            icon: "skip_previous"
            onClicked: MediaService.previous()
          }

          MediaControlButton {
            icon: root.hasActivePlayer ? (MediaService.isPlaying ? "pause" : "play_arrow") : "album"
            onClicked: MediaService.playPause()
          }

          MediaControlButton {
            visible: MediaService.canGoNext
            icon: "skip_next"
            onClicked: MediaService.next()
          }
        }

        Item {
          id: titleContainer
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          Layout.preferredHeight: titleText.height
          clip: true

          property real textWidth: fullTitleMetrics.contentWidth
          property real containerWidth: width
          property bool needsScrolling: textWidth > containerWidth
          property alias containsMouse: titleMouseArea.containsMouse
          property bool isScrolling: titleContainer.containsMouse && titleContainer.needsScrolling
          property bool isResetting: false

          onWidthChanged: isResetting = needsScrolling && !isScrolling

          Connections {
            target: titleMouseArea
            function onContainsMouseChanged() {
              if (!titleContainer.containsMouse)
                titleContainer.isResetting = titleContainer.needsScrolling;
            }
          }

          Item {
            id: scrollContainer
            height: parent.height
            width: parent.width
            property real scrollX: 0
            x: scrollX

            RowLayout {
              spacing: 40

              IText {
                id: titleText
                text: root.hasActivePlayer ? root.getTitle() : root.placeholderText
                pointSize: Style.appearance.font.size.small
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: root.hasActivePlayer ? Text.AlignLeft : Text.AlignHCenter

                onTextChanged: {
                  scrollContainer.scrollX = 0;
                  titleContainer.isResetting = false;
                  if (titleContainer.needsScrolling)
                    scrollStartTimer.restart();
                }
              }

              IText {
                text: root.getTitle()
                font: titleText.font
                pointSize: Style.appearance.font.size.small
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                visible: root.hasActivePlayer && titleContainer.needsScrolling && titleContainer.isScrolling
              }
            }

            NumberAnimation on scrollX {
              running: titleContainer.isResetting
              to: 0
              duration: 300
              easing.type: Easing.OutQuad
              onFinished: titleContainer.isResetting = false
            }

            NumberAnimation on scrollX {
              running: titleContainer.isScrolling && !titleContainer.isResetting
              from: 0
              to: -(titleContainer.textWidth + 50)
              duration: Math.max(4000, root.getTitle().length * 120)
              loops: Animation.Infinite
              easing.type: Easing.Linear
            }

            Timer {
              id: scrollStartTimer
              interval: 1500
              running: titleContainer.needsScrolling && titleContainer.containsMouse
              repeat: false
            }
          }

          MouseArea {
            id: titleMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              VisibilityService.getPanel("media", root.screen).toggle(root);
            }
          }
        }
      }
    }
  }

  component MediaControlButton: Rectangle {
    required property string icon
    signal clicked

    implicitWidth: root.buttonSize
    implicitHeight: root.buttonSize
    color: "transparent"
    radius: Settings.appearance.cornerRadius
    Layout.alignment: Qt.AlignVCenter

    IIcon {
      anchors.centerIn: parent
      icon: parent.icon
      color: ThemeService.palette.mOnSurface
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: {
        if (!root.hasActivePlayer || !MediaService.currentPlayer || !MediaService.canPlay)
          return;
        parent.clicked();
      }
    }
  }
}
