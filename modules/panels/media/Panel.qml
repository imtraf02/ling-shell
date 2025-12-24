pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.config
import qs.commons
import qs.widgets
import qs.widgets.audiospectrum
import qs.services
import ".."

BarPanel {
  id: root

  contentComponent: Item {
    id: content
    implicitWidth: 280 + root.padding * 2
    implicitHeight: 240

    IBox {
      id: box
      anchors.fill: parent
      anchors.margins: root.padding

      Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
          maskEnabled: true
          maskThresholdMin: 0.5
          maskSpreadAtMin: 0.0
          maskSource: ShaderEffectSource {
            sourceItem: Rectangle {
              width: root.width
              height: root.height
              radius: Settings.appearance.cornerRadius
              color: "white"
            }
          }
        }

        Image {
          id: bgImage
          readonly property int dim: 256
          anchors.fill: parent
          source: MediaService.trackArtUrl || WallpaperService.getWallpaper(Screen.name)
          sourceSize: Qt.size(dim, dim)
          fillMode: Image.PreserveAspectCrop

          layer.enabled: true
          layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.25
            blurMax: 16
          }
        }

        Rectangle {
          anchors.fill: parent
          color: ThemeService.palette.mSurfaceContainer
          opacity: 0.85
          radius: Settings.appearance.cornerRadius
        }

        Rectangle {
          anchors.fill: parent
          color: "transparent"
          border.color: Qt.alpha(ThemeService.palette.mOutline, 0.4)
          border.width: 1
          radius: Settings.appearance.cornerRadius
        }

        Loader {
          anchors.fill: parent
          active: true
          sourceComponent: ILinearSpectrum {
            anchors.fill: parent
            values: CavaService.values
            fillColor: ThemeService.palette.mPrimary
            opacity: 0.5
          }
        }
      }

      Rectangle {
        id: playerSelectorButton
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: root.spacing
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        height: Config.bar.sizes.innerHeight
        visible: MediaService.getAvailablePlayers().length > 1
        radius: Settings.appearance.cornerRadius
        color: "transparent"

        property var currentPlayer: MediaService.getAvailablePlayers()[MediaService.selectedPlayerIndex]

        RowLayout {
          anchors.fill: parent
          spacing: root.spacing

          IIcon {
            icon: "arrow_drop_down"
            pointSize: Config.appearance.font.size.extraLarge
            color: ThemeService.palette.mOnSurface
          }

          IText {
            text: playerSelectorButton.currentPlayer ? playerSelectorButton.currentPlayer.identity : ""
            pointSize: Config.appearance.font.size.large
            color: ThemeService.palette.mOnSurface
            Layout.fillWidth: true
          }
        }

        MouseArea {
          id: playerSelectorMouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: {
            var menuItems = [];
            var players = MediaService.getAvailablePlayers();
            for (var i = 0; i < players.length; i++) {
              menuItems.push({
                "label": players[i].identity,
                "action": i.toString(),
                "icon": "album",
                "enabled": true,
                "visible": true
              });
            }
            playerContextMenu.model = menuItems;
            playerContextMenu.openAtItem(playerSelectorButton, playerSelectorButton.x, playerSelectorButton.height);
          }
        }

        IContextMenu {
          id: playerContextMenu
          parent: root
          width: 200

          onTriggered: function (action) {
            var index = parseInt(action);
            if (!isNaN(index)) {
              MediaService.switchToPlayer(index);
            }
          }
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.padding

        ColumnLayout {
          id: fallback
          visible: !main.visible
          spacing: root.spacing

          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
          }
          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
              anchors.centerIn: parent
              spacing: root.spacing

              Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Config.appearance.font.size.extraLarge * 4
                Layout.preferredHeight: Config.appearance.font.size.extraLarge * 4

                Repeater {
                  model: 3
                  delegate: Rectangle {
                    id: rect
                    required property int index
                    anchors.centerIn: parent
                    width: parent.width * (1.0 + index * 0.2)
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.color: ThemeService.palette.mOnSurface
                    border.width: 2
                    opacity: 0

                    SequentialAnimation on opacity {
                      running: true
                      loops: Animation.Infinite
                      PauseAnimation {
                        duration: rect.index * 600
                      }
                      NumberAnimation {
                        from: 1.0
                        to: 0
                        duration: 2000
                        easing.type: Easing.OutQuad
                      }
                    }

                    SequentialAnimation on scale {
                      running: true
                      loops: Animation.Infinite
                      PauseAnimation {
                        duration: rect.index * 600
                      }
                      NumberAnimation {
                        from: 0.6
                        to: 1.2
                        duration: 2000
                        easing.type: Easing.OutQuad
                      }
                    }
                  }
                }

                IIcon {
                  anchors.centerIn: parent
                  icon: "album"
                  pointSize: Config.appearance.font.size.extraLarge * 3
                  color: ThemeService.palette.mOnSurface
                }
              }

              ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: root.spacing
              }
            }
          }
          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
          }
        }

        ColumnLayout {
          id: main
          visible: MediaService.currentPlayer && MediaService.canPlay
          spacing: root.spacing

          Item {
            Layout.preferredHeight: root.spacing
          }

          ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
            spacing: root.spacing

            IText {
              visible: MediaService.trackTitle !== ""
              text: MediaService.trackTitle
              pointSize: Config.appearance.font.size.large
              elide: Text.ElideRight
              wrapMode: Text.Wrap
              maximumLineCount: 2
              Layout.fillWidth: true
            }

            IText {
              visible: MediaService.trackArtist !== ""
              text: MediaService.trackArtist
              color: ThemeService.palette.mPrimary
              pointSize: Config.appearance.font.size.small
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            IText {
              visible: MediaService.trackAlbum !== ""
              text: MediaService.trackAlbum
              color: ThemeService.palette.mOnSurface
              pointSize: Config.appearance.font.size.small
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          Item {
            id: progressWrapper
            visible: (MediaService.currentPlayer && MediaService.trackLength > 0)
            Layout.fillWidth: true
            Layout.preferredHeight: Config.appearance.widget.size * 0.5

            property real localSeekRatio: -1
            property real lastSentSeekRatio: -1
            property real seekEpsilon: 0.01

            property real progressRatio: {
              if (!MediaService.currentPlayer || MediaService.trackLength <= 0)
                return 0;
              const r = MediaService.currentPosition / MediaService.trackLength;
              if (isNaN(r) || !isFinite(r))
                return 0;
              return Math.max(0, Math.min(1, r));
            }

            property real effectiveRatio: (MediaService.isSeeking && localSeekRatio >= 0) ? Math.max(0, Math.min(1, localSeekRatio)) : progressRatio

            Timer {
              id: seekDebounce
              interval: 75
              repeat: false
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

            ISlider {
              id: progressSlider
              anchors.fill: parent
              from: 0
              to: 1
              stepSize: 0
              snapAlways: false
              enabled: MediaService.trackLength > 0 && MediaService.canSeek
              heightRatio: 0.6

              onMoved: {
                progressWrapper.localSeekRatio = value;
                seekDebounce.restart();
              }

              onPressedChanged: {
                if (pressed) {
                  MediaService.isSeeking = true;
                  progressWrapper.localSeekRatio = value;
                  MediaService.seekByRatio(value);
                  progressWrapper.lastSentSeekRatio = value;
                } else {
                  seekDebounce.stop();
                  MediaService.seekByRatio(value);
                  MediaService.isSeeking = false;
                  progressWrapper.localSeekRatio = -1;
                  progressWrapper.lastSentSeekRatio = -1;
                }
              }
            }

            Binding {
              target: progressSlider
              property: "value"
              value: progressWrapper.progressRatio
              when: !MediaService.isSeeking
            }
          }

          Item {
            Layout.preferredHeight: root.spacing
          }

          RowLayout {
            spacing: root.spacing
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            IIconButton {
              icon: "skip_previous"
              visible: MediaService.canGoPrevious
              onClicked: MediaService.canGoPrevious ? MediaService.previous() : {}
            }

            IIconButton {
              icon: MediaService.isPlaying ? "pause" : "play_arrow"
              visible: (MediaService.canPlay || MediaService.canPause)
              onClicked: (MediaService.canPlay || MediaService.canPause) ? MediaService.playPause() : {}
            }

            IIconButton {
              icon: "skip_next"
              visible: MediaService.canGoNext
              onClicked: MediaService.canGoNext ? MediaService.next() : {}
            }
          }
        }
      }
    }
  }
}
