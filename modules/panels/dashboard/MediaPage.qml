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
  property bool active: false
  implicitWidth: 720
  implicitHeight: 380
  readonly property bool shouldVisualize: active && MediaService.isPlaying
  readonly property string consumerId: "dashboard-media-" + (screen?.name || "unknown")

  function formatDuration(value) {
    const seconds = Math.max(0, Math.floor(Number(value) || 0));
    const minutes = Math.floor(seconds / 60);
    return minutes + ":" + String(seconds % 60).padStart(2, "0");
  }
  function updateCava() {
    if (shouldVisualize) CavaService.registerComponent(consumerId);
    else CavaService.unregisterComponent(consumerId);
  }
  onShouldVisualizeChanged: updateCava()
  Component.onCompleted: updateCava()
  Component.onDestruction: CavaService.unregisterComponent(consumerId)

  DashboardCard {
    anchors.fill: parent
    cardColor: ThemeService.palette.mSurfaceContainer

    Item {
      z: -1
      anchors.fill: parent
      opacity: 0.34
      ILinearSpectrum {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * 0.58
        values: CavaService.values
        fillColor: ThemeService.palette.mPrimary
        opacity: 0.7
        showMinimumSignal: false
        barWidthRatio: 0.54
      }
    }

    ColumnLayout {
      anchors.fill: parent
      spacing: Style.spacing.normal

      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 176
        spacing: Style.spacing.large

        Rectangle {
          Layout.preferredWidth: 176
          Layout.preferredHeight: 176
          radius: Style.rounding.large
          color: ThemeService.palette.mSurfaceVariant
          clip: true
          IImageCached { id: artwork; anchors.fill: parent; imagePath: MediaService.trackArtUrl; maxCacheDimension: 512; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
          IIcon { anchors.centerIn: parent; visible: artwork.status !== Image.Ready; icon: "album"; color: ThemeService.palette.mPrimary; font.pointSize: Style.font.size.extraLarge * 2.4 }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Item { Layout.fillHeight: true }
          IText { Layout.fillWidth: true; text: MediaService.trackTitle || "Nothing playing"; font.pointSize: Style.font.size.extraLarge; font.weight: Font.Bold; maximumLineCount: 2; wrapMode: Text.Wrap; elide: Text.ElideRight }
          IText { Layout.fillWidth: true; text: MediaService.trackArtist || "Open a media player to begin"; color: ThemeService.palette.mPrimary; font.pointSize: Style.font.size.large; elide: Text.ElideRight }
          IText { Layout.fillWidth: true; visible: MediaService.trackAlbum !== ""; text: MediaService.trackAlbum; color: ThemeService.palette.mOnSurfaceVariant; elide: Text.ElideRight }
          Flickable {
            id: playerViewport
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            visible: MediaService.getAvailablePlayers().length > 1
            contentWidth: Math.max(width, playerGroup.implicitWidth)
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            IButtonGroup {
              id: playerGroup
              width: Math.max(implicitWidth, playerViewport.width)
              height: playerViewport.height
              segmented: true
              uniformCellSizes: true

              Repeater {
                model: MediaService.getAvailablePlayers()
                delegate: IGroupButton {
                  required property int index
                  required property var modelData
                  text: modelData.identity || "Player"
                  icon: "album"
                  selected: index === MediaService.selectedPlayerIndex
                  bounce: false
                  baseHeight: 30
                  onClicked: MediaService.switchToPlayer(index)
                }
              }
            }
          }
          Item { Layout.fillHeight: true }
        }
      }

      ColumnLayout {
        id: progress
        Layout.fillWidth: true
        spacing: Style.spacing.small
        property real localRatio: -1
        readonly property real sourceRatio: MediaService.trackLength > 0 ? Math.max(0, Math.min(1, MediaService.currentPosition / MediaService.trackLength)) : 0
        readonly property real displayPosition: MediaService.isSeeking && localRatio >= 0 ? localRatio * MediaService.trackLength : MediaService.currentPosition

        RowLayout {
          Layout.fillWidth: true
          IText { text: root.formatDuration(progress.displayPosition); color: ThemeService.palette.mOnSurfaceVariant }
          Item { Layout.fillWidth: true }
          IText { text: MediaService.trackLength > 0 ? root.formatDuration(MediaService.trackLength) : "--:--"; color: ThemeService.palette.mOnSurfaceVariant }
        }
        IWavySlider {
          id: slider
          Layout.fillWidth: true
          from: 0
          to: 1
          enabled: MediaService.trackLength > 0 && MediaService.canSeek
          animateWave: root.shouldVisualize
          onInteractionStarted: value => { MediaService.isSeeking = true; progress.localRatio = value; }
          onInteractionMoved: value => progress.localRatio = value
          onInteractionFinished: value => {
            MediaService.seekByRatio(value);
            MediaService.isSeeking = false;
            progress.localRatio = -1;
          }
        }
        Binding { target: slider; property: "value"; value: progress.sourceRatio; when: !slider.pressed; restoreMode: Binding.RestoreNone }
      }

      IButtonGroup {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: 58
        spacing: 5

        IGroupButton { baseWidth: 36; baseHeight: 36; icon: "replay_10"; enabled: MediaService.canSeek; onClicked: MediaService.seekRelative(-10) }
        IGroupButton { baseWidth: 42; baseHeight: 42; icon: "skip_previous"; enabled: MediaService.canGoPrevious; onClicked: MediaService.previous() }
        IGroupButton { baseWidth: 58; baseHeight: 58; iconSize: Style.font.size.extraLarge; icon: MediaService.isPlaying ? "pause" : "play_arrow"; selected: true; enabled: MediaService.canPlay || MediaService.canPause; onClicked: MediaService.playPause() }
        IGroupButton { baseWidth: 42; baseHeight: 42; icon: "skip_next"; enabled: MediaService.canGoNext; onClicked: MediaService.next() }
        IGroupButton { baseWidth: 36; baseHeight: 36; icon: "forward_10"; enabled: MediaService.canSeek; onClicked: MediaService.seekRelative(10) }
      }
    }
  }
}
