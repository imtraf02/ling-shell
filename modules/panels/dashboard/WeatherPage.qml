pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

Item {
  id: root

  implicitWidth: 872
  implicitHeight: 640

  readonly property bool hasCurrentWeather: WeatherService.current.weather_code !== undefined
  readonly property var currentWeather: hasCurrentWeather ? WeatherService.weatherInfo(WeatherService.current.weather_code, WeatherService.current.is_day) : ({
      description: "Forecast unavailable",
      icon: "partly_cloudy_day"
    })

  function dayName(date) {
    return Qt.formatDate(new Date(date + "T12:00:00"), "ddd");
  }

  function hourLabel(time, index) {
    return index === 0 ? "Now" : Qt.formatTime(new Date(time), "HH:mm");
  }

  function scrollHours(delta) {
    const target = Math.max(0, Math.min(hourlyView.contentWidth - hourlyView.width, hourlyView.contentX + delta));
    if (Math.abs(target - hourlyView.contentX) < 1)
      return;
    hourlyScrollAnimation.stop();
    hourlyScrollAnimation.from = hourlyView.contentX;
    hourlyScrollAnimation.to = target;
    hourlyScrollAnimation.start();
  }

  NumberAnimation {
    id: hourlyScrollAnimation
    target: hourlyView
    property: "contentX"
    duration: 180
    easing.type: Easing.OutQuint
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.spacing.normal

    DashboardCard {
      Layout.fillWidth: true
      Layout.preferredHeight: 226
      cardColor: Qt.tint(ThemeService.palette.mSurfaceContainer, Qt.alpha(ThemeService.palette.mPrimary, 0.05))
      border.width: 1
      border.color: Qt.alpha(ThemeService.palette.mOutline, 0.22)

      RowLayout {
        anchors.fill: parent
        spacing: Style.spacing.large

        Item {
          Layout.preferredWidth: 142
          Layout.fillHeight: true

          Rectangle {
            anchors.centerIn: parent
            width: 124
            height: 124
            radius: Style.rounding.large
            color: Qt.alpha(ThemeService.palette.mPrimary, 0.08)

            IIcon {
              anchors.centerIn: parent
              icon: root.currentWeather.icon
              color: ThemeService.palette.mPrimary
              font.pointSize: Style.font.size.extraLarge * 3
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.minimumWidth: 0
          spacing: 2

          Item {
            Layout.fillHeight: true
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.spacing.small

            IIcon {
              icon: "location_on"
              color: ThemeService.palette.mPrimary
              font.pointSize: Style.font.size.large
            }

            IText {
              Layout.fillWidth: true
              text: WeatherService.locationName || Settings.dashboard.weatherLocation
              font.pointSize: Style.font.size.larger
              font.weight: Font.DemiBold
              elide: Text.ElideRight
            }
          }

          IText {
            text: WeatherService.current.temperature_2m !== undefined ? Math.round(WeatherService.current.temperature_2m) + "°C" : "--°C"
            font.pointSize: Style.font.size.extraLarge * 2.25
            font.weight: Font.Bold
            color: ThemeService.palette.mOnSurface
            animate: true
            animateDuration: 200
          }

          IText {
            Layout.fillWidth: true
            text: WeatherService.loading ? "Updating forecast…" : (WeatherService.error || root.currentWeather.description)
            color: WeatherService.error ? ThemeService.palette.mError : ThemeService.palette.mOnSurfaceVariant
            font.pointSize: Style.font.size.larger
            elide: Text.ElideRight
          }

          RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Style.spacing.small
            spacing: Style.spacing.small

            Rectangle {
              Layout.preferredWidth: feelsLikeRow.implicitWidth + Style.padding.normal * 2
              Layout.preferredHeight: 32
              radius: height / 2
              color: ThemeService.palette.mSurfaceContainerHigh
              border.width: 1
              border.color: Qt.alpha(ThemeService.palette.mOutline, 0.22)

              RowLayout {
                id: feelsLikeRow
                anchors.centerIn: parent
                spacing: Style.spacing.small

                IIcon {
                  icon: "thermostat"
                  color: ThemeService.palette.mPrimary
                  font.pointSize: Style.font.size.large
                }
                IText {
                  text: WeatherService.current.apparent_temperature !== undefined ? "Feels like  " + Math.round(WeatherService.current.apparent_temperature) + "°C" : "Feels like  --"
                  color: ThemeService.palette.mOnSurfaceVariant
                  font.pointSize: Style.font.size.small
                }
              }
            }

            Rectangle {
              Layout.preferredWidth: humidityRow.implicitWidth + Style.padding.normal * 2
              Layout.preferredHeight: 32
              radius: height / 2
              color: ThemeService.palette.mSurfaceContainerHigh
              border.width: 1
              border.color: Qt.alpha(ThemeService.palette.mOutline, 0.22)

              RowLayout {
                id: humidityRow
                anchors.centerIn: parent
                spacing: Style.spacing.small

                IIcon {
                  icon: "humidity_percentage"
                  color: ThemeService.palette.mPrimary
                  font.pointSize: Style.font.size.large
                }
                IText {
                  text: WeatherService.current.relative_humidity_2m !== undefined ? "Humidity  " + Math.round(WeatherService.current.relative_humidity_2m) + "%" : "Humidity  --"
                  color: ThemeService.palette.mOnSurfaceVariant
                  font.pointSize: Style.font.size.small
                }
              }
            }

            Item {
              Layout.fillWidth: true
            }
          }

          Item {
            Layout.fillHeight: true
          }
        }

        ColumnLayout {
          Layout.preferredWidth: 164
          Layout.fillHeight: true
          spacing: Style.spacing.small

          Item {
            Layout.fillHeight: true
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            radius: Style.rounding.small
            color: ThemeService.palette.mSurfaceContainerHigh
            border.width: 1
            border.color: Qt.alpha(ThemeService.palette.mOutline, 0.22)

            RowLayout {
              anchors.fill: parent
              anchors.margins: Style.padding.normal
              spacing: Style.spacing.normal

              IIcon {
                icon: "air"
                color: ThemeService.palette.mPrimary
                font.pointSize: Style.font.size.extraLarge
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                IText {
                  text: "Wind"
                  color: ThemeService.palette.mOnSurfaceVariant
                  font.pointSize: Style.font.size.small
                }
                IText {
                  text: WeatherService.current.wind_speed_10m !== undefined ? Math.round(WeatherService.current.wind_speed_10m) + " km/h" : "-- km/h"
                  font.weight: Font.DemiBold
                  font.pointSize: Style.font.size.larger
                  animate: true
                  animateDuration: 200
                }
              }
            }
          }

          IButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            text: WeatherService.loading ? "Updating…" : "Refresh"
            icon: "refresh"
            enabled: !WeatherService.loading
            outlined: true
            backgroundColor: ThemeService.palette.mPrimary
            textColor: ThemeService.palette.mOnPrimary
            onClicked: WeatherService.reload(true)
          }

          Item {
            Layout.fillHeight: true
          }
        }
      }
    }

    DashboardCard {
      Layout.fillWidth: true
      Layout.preferredHeight: 184
      title: "Next hours"
      icon: "schedule"
      border.width: 1
      border.color: Qt.alpha(ThemeService.palette.mOutline, 0.22)

      ListView {
        id: hourlyView
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: Style.spacing.small
        clip: true
        model: WeatherService.hourly.slice(0, 12)
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        snapMode: ListView.SnapToItem

        delegate: Rectangle {
          id: hourCard
          required property int index
          required property var modelData

          width: 102
          height: ListView.view.height
          radius: Style.rounding.small
          color: index === 0 ? Qt.alpha(ThemeService.palette.mPrimary, 0.12) : ThemeService.palette.mSurfaceContainerHigh
          border.width: 1
          border.color: index === 0 ? Qt.alpha(ThemeService.palette.mPrimary, 0.5) : Qt.alpha(ThemeService.palette.mOutline, 0.18)

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 2

            IText {
              Layout.alignment: Qt.AlignHCenter
              text: root.hourLabel(hourCard.modelData.time, hourCard.index)
              color: hourCard.index === 0 ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurfaceVariant
              font.pointSize: Style.font.size.small
              font.weight: hourCard.index === 0 ? Font.DemiBold : Font.Normal
            }
            IIcon {
              Layout.alignment: Qt.AlignHCenter
              icon: hourCard.modelData.icon
              color: ThemeService.palette.mPrimary
              font.pointSize: Style.font.size.extraLarge
            }
            IText {
              Layout.alignment: Qt.AlignHCenter
              text: Math.round(hourCard.modelData.temperature) + "°"
              font.weight: Font.Bold
              font.pointSize: Style.font.size.larger
            }
            IText {
              Layout.alignment: Qt.AlignHCenter
              text: Math.round(hourCard.modelData.precipitation || 0) + "% rain"
              color: ThemeService.palette.mOnSurfaceVariant
              font.pointSize: Style.font.size.small
            }
          }
        }
      }

      IText {
        anchors.centerIn: parent
        visible: hourlyView.count === 0
        text: WeatherService.loading ? "Loading hourly forecast…" : "Hourly forecast unavailable"
        color: ThemeService.palette.mOnSurfaceVariant
        font.pointSize: Style.font.size.small
      }

      IIconButton {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: -Style.padding.small
        visible: hourlyView.contentX > 2
        size: 34
        icon: "chevron_left"
        colorBg: ThemeService.palette.mSurfaceContainerHighest
        colorFg: ThemeService.palette.mOnSurface
        onClicked: root.scrollHours(-hourlyView.width * 0.72)
      }

      IIconButton {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: -Style.padding.small
        visible: hourlyView.contentWidth > hourlyView.width && hourlyView.contentX < hourlyView.contentWidth - hourlyView.width - 2
        size: 34
        icon: "chevron_right"
        colorBg: ThemeService.palette.mSurfaceContainerHighest
        colorFg: ThemeService.palette.mOnSurface
        onClicked: root.scrollHours(hourlyView.width * 0.72)
      }
    }

    DashboardCard {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.minimumHeight: 206
      title: "7-day forecast"
      icon: "date_range"
      border.width: 1
      border.color: Qt.alpha(ThemeService.palette.mOutline, 0.22)

      RowLayout {
        anchors.fill: parent
        spacing: Style.spacing.small

        Repeater {
          model: WeatherService.daily

          delegate: Rectangle {
            id: dayCard
            required property int index
            required property var modelData

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            radius: Style.rounding.small
            color: index === 0 ? Qt.alpha(ThemeService.palette.mPrimary, 0.12) : ThemeService.palette.mSurfaceContainerHigh
            border.width: 1
            border.color: index === 0 ? Qt.alpha(ThemeService.palette.mPrimary, 0.5) : Qt.alpha(ThemeService.palette.mOutline, 0.18)

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 2

              IText {
                Layout.alignment: Qt.AlignHCenter
                text: root.dayName(dayCard.modelData.date)
                color: dayCard.index === 0 ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurface
                font.weight: Font.DemiBold
              }
              IIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: dayCard.modelData.icon
                color: ThemeService.palette.mPrimary
                font.pointSize: Style.font.size.extraLarge
              }
              RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Style.spacing.small
                IText {
                  text: Math.round(dayCard.modelData.high) + "°"
                  font.weight: Font.Bold
                  font.pointSize: Style.font.size.larger
                }
                IText {
                  text: Math.round(dayCard.modelData.low) + "°"
                  color: ThemeService.palette.mOnSurfaceVariant
                  font.pointSize: Style.font.size.small
                }
              }
            }
          }
        }
      }

      IText {
        anchors.centerIn: parent
        visible: WeatherService.daily.length === 0
        text: WeatherService.loading ? "Loading 7-day forecast…" : "7-day forecast unavailable"
        color: ThemeService.palette.mOnSurfaceVariant
        font.pointSize: Style.font.size.small
      }
    }
  }
}
