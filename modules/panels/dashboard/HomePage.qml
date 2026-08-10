pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.common
import qs.services
import qs.widgets
import qs.utils

Item {
  id: root

  required property ShellScreen screen
  property bool active: false
  implicitWidth: 872
  implicitHeight: 472

  readonly property real mediaRatio: MediaService.trackLength > 0
    ? Math.max(0, Math.min(1, MediaService.currentPosition / MediaService.trackLength)) : 0

  function formatDuration(value) {
    const seconds = Math.max(0, Math.floor(Number(value) || 0));
    return Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0");
  }

  function calendarCell(index) {
    const today = TimeService.date;
    const first = new Date(today.getFullYear(), today.getMonth(), 1);
    const offset = (first.getDay() + 6) % 7;
    const day = index - offset + 1;
    const days = new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate();
    return {
      day: day,
      currentMonth: day > 0 && day <= days,
      today: day === today.getDate()
    };
  }

  RowLayout {
    anchors.fill: parent
    spacing: Style.spacing.normal

    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.minimumWidth: 0
      spacing: Style.spacing.normal

      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 166
        Layout.minimumHeight: 166
        Layout.maximumHeight: 166
        spacing: Style.spacing.normal

        DashboardCard {
          Layout.preferredWidth: 236
          Layout.minimumWidth: 210
          Layout.maximumWidth: 236
          Layout.fillHeight: true
          cardColor: Qt.tint(ThemeService.palette.mSurfaceContainer, Qt.alpha(ThemeService.palette.mPrimary, 0.06))

          RowLayout {
            anchors.fill: parent
            spacing: Style.spacing.normal

            IIcon {
              icon: WeatherService.current.weather_code !== undefined
                ? WeatherService.weatherInfo(WeatherService.current.weather_code, WeatherService.current.is_day).icon
                : "partly_cloudy_day"
              color: ThemeService.palette.mPrimary
              font.pointSize: Style.font.size.extraLarge * 2.25
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1
              IText {
                Layout.fillWidth: true
                text: WeatherService.locationName || Settings.dashboard.weatherLocation
                color: ThemeService.palette.mOnSurfaceVariant
                font.pointSize: Style.font.size.small
                elide: Text.ElideRight
              }
              IText {
                text: WeatherService.current.temperature_2m !== undefined
                  ? Math.round(WeatherService.current.temperature_2m) + "°"
                  : "--°"
                font.pointSize: Style.font.size.extraLarge * 1.65
                font.weight: Font.Bold
              }
              IText {
                Layout.fillWidth: true
                text: WeatherService.loading ? "Updating…" : (WeatherService.error ||
                  (WeatherService.current.weather_code !== undefined
                    ? WeatherService.weatherInfo(WeatherService.current.weather_code, WeatherService.current.is_day).description
                    : "Forecast unavailable"))
                color: WeatherService.error ? ThemeService.palette.mError : ThemeService.palette.mOnSurfaceVariant
                font.pointSize: Style.font.size.small
                elide: Text.ElideRight
              }
            }
          }
        }

        DashboardCard {
          Layout.fillWidth: true
          Layout.minimumWidth: 0
          Layout.fillHeight: true
          cardColor: ThemeService.palette.mSurfaceContainerHigh

          RowLayout {
            anchors.fill: parent
            spacing: Style.spacing.large

            Rectangle {
              Layout.preferredWidth: 92
              Layout.preferredHeight: 92
              radius: width / 2
              color: ThemeService.palette.mSurfaceVariant
              clip: true

              IImageCached {
                id: avatar
                anchors.fill: parent
                imagePath: FileUtils.trimFileProtocol(Settings.general.avatarImage)
                maxCacheDimension: 256
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
              }
              IIcon {
                anchors.centerIn: parent
                visible: avatar.status !== Image.Ready
                icon: "person"
                color: ThemeService.palette.mPrimary
                font.pointSize: Style.font.size.extraLarge * 1.7
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 3
              IText {
                Layout.fillWidth: true
                text: TimeService.hours < 12 ? "Good morning" : (TimeService.hours < 18 ? "Good afternoon" : "Good evening")
                color: ThemeService.palette.mOnSurfaceVariant
                font.pointSize: Style.font.size.small
              }
              IText {
                Layout.fillWidth: true
                text: DistroService.user || "User"
                font.pointSize: Style.font.size.extraLarge
                font.weight: Font.Bold
                font.capitalization: Font.Capitalize
                elide: Text.ElideRight
              }
              Flow {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: Style.spacing.small
                StatusChip { icon: "deployed_code"; text: DistroService.osPretty || "NixOS" }
                StatusChip { icon: "schedule"; text: DistroService.uptime }
              }
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.spacing.normal

        DashboardCard {
          Layout.preferredWidth: 126
          Layout.minimumWidth: 116
          Layout.maximumWidth: 126
          Layout.fillHeight: true
          cardColor: Qt.tint(ThemeService.palette.mSurfaceContainer, Qt.alpha(ThemeService.palette.mSecondary, 0.05))

          ColumnLayout {
            anchors.fill: parent
            spacing: 0
            Item { Layout.fillHeight: true }
            IText {
              Layout.alignment: Qt.AlignHCenter
              text: TimeService.format("HH:mm")
              font.pointSize: Style.font.size.extraLarge
              font.weight: Font.Bold
              color: ThemeService.palette.mPrimary
            }
            IText {
              Layout.alignment: Qt.AlignHCenter
              text: TimeService.format("ddd")
              font.pointSize: Style.font.size.large
              font.weight: Font.DemiBold
            }
            IText {
              Layout.alignment: Qt.AlignHCenter
              text: TimeService.format("d MMM")
              color: ThemeService.palette.mOnSurfaceVariant
            }
            Item { Layout.fillHeight: true }
          }
        }

        DashboardCard {
          Layout.fillWidth: true
          Layout.minimumWidth: 0
          Layout.fillHeight: true
          title: TimeService.format("MMMM yyyy")
          icon: "calendar_month"

          ColumnLayout {
            anchors.fill: parent
            spacing: 2

            GridLayout {
              Layout.fillWidth: true
              columns: 7
              columnSpacing: 1
              rowSpacing: 0
              Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]
                delegate: IText {
                  required property string modelData
                  Layout.fillWidth: true
                  Layout.preferredHeight: 18
                  text: modelData
                  horizontalAlignment: Text.AlignHCenter
                  color: ThemeService.palette.mOnSurfaceVariant
                  font.pointSize: Style.font.size.small
                  font.weight: Font.Medium
                }
              }
            }

            GridLayout {
              Layout.fillWidth: true
              Layout.fillHeight: true
              columns: 7
              columnSpacing: 1
              rowSpacing: 1

              Repeater {
                model: 42
                delegate: Item {
                  id: dayCell
                  required property int index
                  readonly property var cell: root.calendarCell(index)
                  Layout.fillWidth: true
                  Layout.fillHeight: true

                  Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(0, Math.min(27, parent.width - 2, parent.height - 2))
                    height: width
                    radius: width / 2
                    color: dayCell.cell.today ? ThemeService.palette.mPrimary : "transparent"
                    IText {
                      anchors.centerIn: parent
                      text: dayCell.cell.currentMonth ? dayCell.cell.day : ""
                      color: dayCell.cell.today ? ThemeService.palette.mOnPrimary : ThemeService.palette.mOnSurface
                      font.pointSize: Style.font.size.small
                      font.weight: dayCell.cell.today ? Font.Bold : Font.Normal
                    }
                  }
                }
              }
            }
          }
        }

        DashboardCard {
          Layout.preferredWidth: 154
          Layout.minimumWidth: 144
          Layout.maximumWidth: 154
          Layout.fillHeight: true
          title: "Resources"
          icon: "monitoring"

          ColumnLayout {
            anchors.fill: parent
            spacing: Style.spacing.normal
            Item { Layout.fillHeight: true }
            MetricRow { icon: "memory"; label: "CPU"; value: SystemUsageService.cpuUsage; accent: SystemUsageService.cpuColor }
            MetricRow { icon: "developer_board"; label: "Memory"; value: SystemUsageService.memPercent; accent: SystemUsageService.memColor }
            MetricRow { icon: "hard_drive"; label: "Storage"; value: SystemUsageService.diskPercents["/"] || 0; accent: SystemUsageService.getDiskColor("/") }
            MetricRow {
              visible: UPower.displayDevice.isLaptopBattery
              icon: "battery_full"
              label: "Battery"
              value: UPower.displayDevice.percentage * 100
              accent: ThemeService.palette.mSecondary
            }
            Item { Layout.fillHeight: true }
          }
        }
      }
    }

    DashboardCard {
      Layout.preferredWidth: 218
      Layout.minimumWidth: 218
      Layout.maximumWidth: 218
      Layout.fillHeight: true
      title: "Now playing"
      icon: "music_note"
      cardColor: Qt.tint(ThemeService.palette.mSurfaceContainer, Qt.alpha(ThemeService.palette.mPrimary, 0.045))

      ColumnLayout {
        anchors.fill: parent
        spacing: Style.spacing.small

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: width
          Layout.maximumHeight: 188
          radius: Style.rounding.large
          color: ThemeService.palette.mSurfaceVariant
          clip: true

          IImageCached {
            id: artwork
            anchors.fill: parent
            imagePath: MediaService.trackArtUrl
            maxCacheDimension: 512
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
          }
          IIcon {
            anchors.centerIn: parent
            visible: artwork.status !== Image.Ready
            icon: "album"
            color: ThemeService.palette.mPrimary
            font.pointSize: Style.font.size.extraLarge * 2.1
          }
        }

        IText {
          Layout.fillWidth: true
          text: MediaService.trackTitle || "Nothing playing"
          font.pointSize: Style.font.size.large
          font.weight: Font.Bold
          maximumLineCount: 2
          wrapMode: Text.Wrap
          elide: Text.ElideRight
        }
        IText {
          Layout.fillWidth: true
          text: MediaService.trackArtist || "Open a media player"
          color: ThemeService.palette.mOnSurfaceVariant
          font.pointSize: Style.font.size.small
          elide: Text.ElideRight
        }

        Item { Layout.fillHeight: true }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 1
          RowLayout {
            Layout.fillWidth: true
            IText { text: root.formatDuration(MediaService.currentPosition); color: ThemeService.palette.mOnSurfaceVariant; font.pointSize: Style.font.size.small }
            Item { Layout.fillWidth: true }
            IText { text: MediaService.trackLength > 0 ? root.formatDuration(MediaService.trackLength) : "--:--"; color: ThemeService.palette.mOnSurfaceVariant; font.pointSize: Style.font.size.small }
          }
          IWavySlider {
            id: mediaProgress
            Layout.fillWidth: true
            implicitHeight: 26
            from: 0
            to: 1
            value: root.mediaRatio
            enabled: MediaService.trackLength > 0 && MediaService.canSeek
            waveAmplitude: 1.5
            handleHeight: 18
            onInteractionStarted: value => MediaService.isSeeking = true
            onInteractionFinished: value => {
              MediaService.seekByRatio(value);
              MediaService.isSeeking = false;
            }
          }
          Binding { target: mediaProgress; property: "value"; value: root.mediaRatio; when: !mediaProgress.pressed; restoreMode: Binding.RestoreNone }
        }

        RowLayout {
          Layout.alignment: Qt.AlignHCenter
          spacing: Style.spacing.small
          IIconButton { size: 32; radius: size / 2; icon: "skip_previous"; enabled: MediaService.canGoPrevious; colorBg: "transparent"; onClicked: MediaService.previous() }
          IIconButton {
            size: 42
            radius: size / 2
            icon: MediaService.isPlaying ? "pause" : "play_arrow"
            enabled: MediaService.canPlay || MediaService.canPause
            colorBg: ThemeService.palette.mPrimary
            colorFg: ThemeService.palette.mOnPrimary
            onClicked: MediaService.playPause()
          }
          IIconButton { size: 32; radius: size / 2; icon: "skip_next"; enabled: MediaService.canGoNext; colorBg: "transparent"; onClicked: MediaService.next() }
        }
      }
    }
  }

  component StatusChip: Rectangle {
    id: chip
    property string icon: ""
    property string text: ""
    implicitWidth: chipRow.implicitWidth + Style.padding.small * 2
    implicitHeight: 26
    radius: Style.rounding.full
    color: ThemeService.palette.mSurfaceVariant
    RowLayout {
      id: chipRow
      anchors.centerIn: parent
      spacing: 4
      IIcon { icon: chip.icon; color: ThemeService.palette.mPrimary; font.pointSize: Style.font.size.normal }
      IText { text: chip.text; font.pointSize: Style.font.size.small; maximumLineCount: 1 }
    }
  }

  component MetricRow: Item {
    id: metric
    property string icon: "monitoring"
    property string label: ""
    property real value: 0
    property color accent: ThemeService.palette.mPrimary
    Layout.fillWidth: true
    implicitHeight: 36

    RowLayout {
      anchors.fill: parent
      spacing: Style.spacing.small
      IIcon { icon: metric.icon; color: metric.accent; font.pointSize: Style.font.size.large }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 3
        RowLayout {
          Layout.fillWidth: true
          IText { Layout.fillWidth: true; text: metric.label; font.pointSize: Style.font.size.small; elide: Text.ElideRight }
          IText { text: Math.round(metric.value) + "%"; color: metric.accent; font.pointSize: Style.font.size.small; font.weight: Font.Bold }
        }
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 4
          radius: height / 2
          color: ThemeService.palette.mSurfaceVariant
          Rectangle {
            width: parent.width * Math.max(0, Math.min(100, metric.value)) / 100
            height: parent.height
            radius: height / 2
            color: metric.accent
          }
        }
      }
    }
  }
}
