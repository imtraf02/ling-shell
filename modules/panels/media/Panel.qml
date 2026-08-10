pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.modules.panels
import qs.widgets
import qs.services

SmartPanel {
  id: root

  readonly property bool shouldVisualize: root.isPanelOpen && MediaService.isPlaying

  function cavaId() {
    return "media-panel-" + (root.screen?.name || "unknown");
  }

  function formatDuration(value) {
    const seconds = Math.max(0, Math.floor(Number(value) || 0));
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const remainder = seconds % 60;
    if (hours > 0)
      return `${hours}:${String(minutes).padStart(2, "0")}:${String(remainder).padStart(2, "0")}`;
    return `${minutes}:${String(remainder).padStart(2, "0")}`;
  }

  onShouldVisualizeChanged: {
    if (shouldVisualize)
      CavaService.registerComponent(cavaId());
    else
      CavaService.unregisterComponent(cavaId());
  }

  Component.onCompleted: {
    if (shouldVisualize)
      CavaService.registerComponent(cavaId());
  }
  Component.onDestruction: CavaService.unregisterComponent(cavaId())

  panelContent: Item {
    id: panelContent
    anchors.fill: parent

    readonly property real contentPreferredWidth: 520
    readonly property real contentPreferredHeight: 270

    IBox {
      id: card
      anchors.fill: parent
      anchors.margins: Style.padding.small
      color: "transparent"
      clip: true

      Rectangle {
        z: -1
        anchors.fill: parent
        radius: card.radius
        opacity: 0.90
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop {
            position: 0
            color: Qt.tint(ThemeService.palette.mSurfaceContainer, Qt.alpha(ThemeService.palette.mPrimary, 0.11))
          }
          GradientStop { position: 0.48; color: ThemeService.palette.mSurfaceContainer }
          GradientStop { position: 1; color: ThemeService.palette.mSurfaceContainer }
        }
      }

      Item {
        id: spectrumBackground
        z: -2
        anchors.fill: parent

        readonly property bool live: root.shouldVisualize && CavaService.available
        readonly property var fallbackValues: [
          0.08, 0.13, 0.10, 0.17, 0.12, 0.20,
          0.15, 0.11, 0.18, 0.24, 0.14, 0.10,
          0.16, 0.21, 0.13, 0.09, 0.15, 0.19,
          0.12, 0.17, 0.11, 0.14, 0.09, 0.13
        ]

        ILinearSpectrum {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.leftMargin: Style.padding.normal
          anchors.rightMargin: Style.padding.normal
          height: parent.height * 0.58
          visible: !spectrumBackground.live
          values: spectrumBackground.fallbackValues
          fillColor: ThemeService.palette.mPrimary
          opacity: 0.22
          barWidthRatio: 0.48
        }

        Loader {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.leftMargin: Style.padding.normal
          anchors.rightMargin: Style.padding.normal
          height: parent.height * 0.58
          active: spectrumBackground.live

          sourceComponent: ILinearSpectrum {
            values: CavaService.values
            fillColor: ThemeService.palette.mPrimary
            opacity: 0.42
            showMinimumSignal: true
            minimumSignalValue: 0.025
            barWidthRatio: 0.48
          }
        }
      }

      ColumnLayout {
        z: 0
        anchors.fill: parent
        anchors.margins: Style.padding.large
        spacing: Style.spacing.small

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: 92
          spacing: Style.spacing.normal

          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.spacing.small

            Item { Layout.fillHeight: true }

            IText {
              Layout.fillWidth: true
              text: MediaService.trackTitle || "Nothing playing"
              font.pointSize: Style.font.size.larger
              font.weight: Font.Bold
              wrapMode: Text.Wrap
              maximumLineCount: 2
              elide: Text.ElideRight
            }

            Rectangle {
              id: playerSelectorButton
              Layout.fillWidth: true
              Layout.preferredHeight: Math.max(28, artistRow.implicitHeight + Style.padding.small)
              color: selectorMouse.containsMouse && MediaService.getAvailablePlayers().length > 1
                ? Qt.alpha(ThemeService.palette.mPrimary, 0.10)
                : "transparent"
              radius: Style.rounding.small

              RowLayout {
                id: artistRow
                anchors.fill: parent
                anchors.leftMargin: Style.padding.small
                anchors.rightMargin: Style.padding.small
                spacing: Style.spacing.small

                IText {
                  Layout.fillWidth: true
                  text: MediaService.trackArtist || MediaService.trackAlbum || "Open a media player to begin"
                  color: ThemeService.palette.mPrimary
                  font.pointSize: Style.font.size.normal
                  font.weight: Font.Medium
                }

                IIcon {
                  visible: MediaService.getAvailablePlayers().length > 1
                  icon: "expand_more"
                  color: ThemeService.palette.mPrimary
                  font.pointSize: Style.font.size.large
                }
              }

              MouseArea {
                id: selectorMouse
                anchors.fill: parent
                enabled: MediaService.getAvailablePlayers().length > 1
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                  const players = MediaService.getAvailablePlayers();
                  const items = [];
                  for (let i = 0; i < players.length; i++) {
                    items.push({
                      label: players[i].identity,
                      action: i.toString(),
                      icon: "album",
                      enabled: true,
                      visible: true
                    });
                  }
                  playerContextMenu.model = items;
                  playerContextMenu.openAtItem(playerSelectorButton, 0, playerSelectorButton.height);
                }
              }
            }

            IText {
              Layout.fillWidth: true
              visible: MediaService.trackArtist !== "" && MediaService.trackAlbum !== ""
              text: MediaService.trackAlbum
              color: ThemeService.palette.mOnSurfaceVariant
              font.pointSize: Style.font.size.small
            }

            Item { Layout.fillHeight: true }
          }

          ClippingRectangle {
            Layout.preferredWidth: 92
            Layout.preferredHeight: 92
            radius: Style.rounding.normal
            color: ThemeService.palette.mSurfaceContainerHigh

            IImageCached {
              id: artwork
              anchors.fill: parent
              imagePath: MediaService.trackArtUrl
              maxCacheDimension: 256
              visible: status === Image.Ready
              fillMode: Image.PreserveAspectCrop
            }

            IIcon {
              anchors.centerIn: parent
              visible: artwork.status !== Image.Ready
              icon: "album"
              color: ThemeService.palette.mPrimary
              font.pointSize: Style.font.size.extraLarge * 1.8
            }
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: 4
        }

        ColumnLayout {
          id: progressWrapper
          Layout.fillWidth: true
          spacing: 0

          property real localSeekRatio: -1
          property real lastSentSeekRatio: -1
          property real seekEpsilon: 0.01
          readonly property real progressRatio: {
            if (!MediaService.currentPlayer || MediaService.trackLength <= 0)
              return 0;
            const ratio = MediaService.currentPosition / MediaService.trackLength;
            return isFinite(ratio) ? Math.max(0, Math.min(1, ratio)) : 0;
          }
          readonly property real effectiveRatio: MediaService.isSeeking && localSeekRatio >= 0
            ? Math.max(0, Math.min(1, localSeekRatio))
            : progressRatio
          readonly property real displayPosition: MediaService.isSeeking && MediaService.trackLength > 0
            ? effectiveRatio * MediaService.trackLength
            : MediaService.currentPosition

          RowLayout {
            Layout.fillWidth: true

            IText {
              text: root.formatDuration(progressWrapper.displayPosition)
              color: ThemeService.palette.mOnSurfaceVariant
              font.pointSize: Style.font.size.small
            }

            Item { Layout.fillWidth: true }

            IText {
              text: MediaService.trackLength > 0 ? root.formatDuration(MediaService.trackLength) : "--:--"
              color: ThemeService.palette.mOnSurfaceVariant
              font.pointSize: Style.font.size.small
            }
          }

          Timer {
            id: seekDebounce
            interval: 75
            onTriggered: {
              if (MediaService.isSeeking && progressWrapper.localSeekRatio >= 0) {
                const next = Math.max(0, Math.min(1, progressWrapper.localSeekRatio));
                if (progressWrapper.lastSentSeekRatio < 0 || Math.abs(next - progressWrapper.lastSentSeekRatio) >= progressWrapper.seekEpsilon) {
                  MediaService.seekByRatio(next);
                  progressWrapper.lastSentSeekRatio = next;
                }
              }
            }
          }

          IWavySlider {
            id: progressSlider
            Layout.fillWidth: true
            from: 0
            to: 1
            enabled: MediaService.trackLength > 0 && MediaService.canSeek
            animateWave: root.shouldVisualize

            onInteractionStarted: value => {
              MediaService.isSeeking = true;
              progressWrapper.localSeekRatio = value;
              progressWrapper.lastSentSeekRatio = -1;
            }

            onInteractionMoved: value => {
              progressWrapper.localSeekRatio = value;
              seekDebounce.restart();
            }

            onInteractionFinished: value => {
              const finalRatio = Math.max(0, Math.min(1, value));
              seekDebounce.stop();
              progressWrapper.localSeekRatio = finalRatio;
              MediaService.seekByRatio(finalRatio);
              MediaService.isSeeking = false;
              progressWrapper.localSeekRatio = -1;
              progressWrapper.lastSentSeekRatio = -1;
            }
          }

          Binding {
            target: progressSlider
            property: "value"
            value: progressWrapper.progressRatio
            when: !progressSlider.pressed
            restoreMode: Binding.RestoreNone
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: 50
          Layout.alignment: Qt.AlignHCenter
          spacing: Style.spacing.normal

          IIconButton {
            size: 34
            radius: size / 2
            icon: "replay_10"
            enabled: MediaService.canSeek
            colorBg: "transparent"
            colorBgHover: ThemeService.palette.mSurfaceContainerHigh
            onClicked: MediaService.seekRelative(-10)
          }

          IIconButton {
            size: 38
            radius: size / 2
            icon: "skip_previous"
            enabled: MediaService.canGoPrevious
            colorBg: "transparent"
            colorBgHover: ThemeService.palette.mSurfaceContainerHigh
            onClicked: MediaService.previous()
          }

          IIconButton {
            size: 50
            radius: size / 2
            icon: MediaService.isPlaying ? "pause" : "play_arrow"
            enabled: MediaService.canPlay || MediaService.canPause
            colorBg: ThemeService.palette.mPrimary
            colorFg: ThemeService.palette.mOnPrimary
            colorBgHover: ThemeService.palette.mPrimaryContainer
            colorFgHover: ThemeService.palette.mOnPrimaryContainer
            onClicked: MediaService.playPause()
          }

          IIconButton {
            size: 38
            radius: size / 2
            icon: "skip_next"
            enabled: MediaService.canGoNext
            colorBg: "transparent"
            colorBgHover: ThemeService.palette.mSurfaceContainerHigh
            onClicked: MediaService.next()
          }

          IIconButton {
            size: 34
            radius: size / 2
            icon: "forward_10"
            enabled: MediaService.canSeek
            colorBg: "transparent"
            colorBgHover: ThemeService.palette.mSurfaceContainerHigh
            onClicked: MediaService.seekRelative(10)
          }
        }
      }

      IContextMenu {
        id: playerContextMenu
        parent: root
        width: 220

        onTriggered: action => {
          const index = parseInt(action);
          if (!isNaN(index))
            MediaService.switchToPlayer(index);
        }
      }
    }
  }
}
