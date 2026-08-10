pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

Item {
  id: root

  implicitWidth: 808
  implicitHeight: 510

  function dayName(date) {
    return Qt.formatDate(new Date(date + "T12:00:00"), "ddd");
  }
  function hourLabel(time) {
    return Qt.formatTime(new Date(time), "HH:mm");
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.spacing.normal

    DashboardCard {
      Layout.fillWidth: true
      Layout.preferredHeight: 180

      RowLayout {
        anchors.fill: parent
        spacing: Style.spacing.large
        IIcon {
          icon: WeatherService.current.weather_code !== undefined ? WeatherService.weatherInfo(WeatherService.current.weather_code, WeatherService.current.is_day).icon : "partly_cloudy_day"
          color: ThemeService.palette.mPrimary
          font.pointSize: Style.font.size.extraLarge * 3
        }
        ColumnLayout {
          Layout.fillWidth: true
          IText { Layout.fillWidth: true; text: WeatherService.locationName || Settings.dashboard.weatherLocation; font.pointSize: Style.font.size.larger; font.weight: Font.Bold; elide: Text.ElideRight }
          IText { text: WeatherService.current.temperature_2m !== undefined ? Math.round(WeatherService.current.temperature_2m) + "°C" : "--°C"; font.pointSize: Style.font.size.extraLarge * 2; font.weight: Font.Bold }
          IText { text: WeatherService.loading ? "Updating forecast…" : (WeatherService.error || (WeatherService.current.weather_code !== undefined ? WeatherService.weatherInfo(WeatherService.current.weather_code, WeatherService.current.is_day).description : "No forecast available")); color: WeatherService.error ? ThemeService.palette.mError : ThemeService.palette.mOnSurfaceVariant }
        }
        ColumnLayout {
          IText { text: WeatherService.current.apparent_temperature !== undefined ? "Feels like  " + Math.round(WeatherService.current.apparent_temperature) + "°C" : "Feels like  --" }
          IText { text: WeatherService.current.relative_humidity_2m !== undefined ? "Humidity  " + WeatherService.current.relative_humidity_2m + "%" : "Humidity  --" }
          IText { text: WeatherService.current.wind_speed_10m !== undefined ? "Wind  " + Math.round(WeatherService.current.wind_speed_10m) + " km/h" : "Wind  --" }
          IButton { text: "Refresh"; icon: "refresh"; enabled: !WeatherService.loading; outlined: true; onClicked: WeatherService.reload(true) }
        }
      }
    }

    DashboardCard {
      Layout.fillWidth: true
      Layout.preferredHeight: 142
      title: "Next hours"
      icon: "schedule"

      ListView {
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: Style.spacing.small
        clip: true
        model: WeatherService.hourly.slice(0, 12)
        delegate: Rectangle {
          required property var modelData
          width: 92
          height: ListView.view.height
          radius: Style.rounding.small
          color: ThemeService.palette.mSurfaceVariant
          ColumnLayout {
            anchors.centerIn: parent
            IText { Layout.alignment: Qt.AlignHCenter; text: root.hourLabel(modelData.time); color: ThemeService.palette.mOnSurfaceVariant; font.pointSize: Style.font.size.small }
            IIcon { Layout.alignment: Qt.AlignHCenter; icon: modelData.icon; color: ThemeService.palette.mPrimary; font.pointSize: Style.font.size.extraLarge }
            IText { Layout.alignment: Qt.AlignHCenter; text: Math.round(modelData.temperature) + "°"; font.weight: Font.Bold }
            IText { Layout.alignment: Qt.AlignHCenter; text: (modelData.precipitation || 0) + "% rain"; color: ThemeService.palette.mOnSurfaceVariant; font.pointSize: Style.font.size.small }
          }
        }
      }
    }

    DashboardCard {
      Layout.fillWidth: true
      Layout.fillHeight: true
      title: "7-day forecast"
      icon: "date_range"

      RowLayout {
        anchors.fill: parent
        spacing: Style.spacing.small
        Repeater {
          model: WeatherService.daily
          delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Style.rounding.small
            color: ThemeService.palette.mSurfaceVariant
            ColumnLayout {
              anchors.centerIn: parent
              IText { Layout.alignment: Qt.AlignHCenter; text: root.dayName(modelData.date); font.weight: Font.Medium }
              IIcon { Layout.alignment: Qt.AlignHCenter; icon: modelData.icon; color: ThemeService.palette.mPrimary; font.pointSize: Style.font.size.extraLarge }
              IText { Layout.alignment: Qt.AlignHCenter; text: Math.round(modelData.high) + "°"; font.weight: Font.Bold }
              IText { Layout.alignment: Qt.AlignHCenter; text: Math.round(modelData.low) + "°"; color: ThemeService.palette.mOnSurfaceVariant }
            }
          }
        }
      }
    }
  }
}
