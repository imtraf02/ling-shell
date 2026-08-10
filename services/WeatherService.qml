pragma Singleton

import QtQuick
import Quickshell
import qs.common

Singleton {
  id: root

  property var consumers: ({})
  readonly property bool active: Object.keys(consumers).length > 0
  property bool loading: false
  property string error: ""
  property string locationName: ""
  property string timezone: ""
  property var current: ({})
  property var hourly: []
  property var daily: []
  property double lastUpdated: 0
  property int requestGeneration: 0

  readonly property int refreshInterval: Math.max(300000, Settings.dashboard.weatherRefreshInterval || 1800000)

  function isStale() {
    return lastUpdated <= 0 || Date.now() - lastUpdated >= refreshInterval;
  }

  function setConsumer(id, enabled) {
    const next = Object.assign({}, consumers);
    if (enabled)
      next[id] = true;
    else
      delete next[id];
    consumers = next;
    if (active && isStale())
      reload(false);
  }

  function weatherInfo(code, isDay) {
    const value = Number(code);
    if (value === 0)
      return { description: "Clear sky", icon: isDay === 0 ? "clear_night" : "sunny" };
    if (value === 1)
      return { description: "Mainly clear", icon: isDay === 0 ? "partly_cloudy_night" : "partly_cloudy_day" };
    if (value === 2)
      return { description: "Partly cloudy", icon: isDay === 0 ? "partly_cloudy_night" : "partly_cloudy_day" };
    if (value === 3)
      return { description: "Overcast", icon: "cloud" };
    if (value === 45 || value === 48)
      return { description: "Fog", icon: "foggy" };
    if (value >= 51 && value <= 57)
      return { description: "Drizzle", icon: "rainy_light" };
    if (value >= 61 && value <= 67)
      return { description: "Rain", icon: "rainy" };
    if (value >= 71 && value <= 77)
      return { description: "Snow", icon: "weather_snowy" };
    if (value >= 80 && value <= 82)
      return { description: "Rain showers", icon: "rainy" };
    if (value >= 85 && value <= 86)
      return { description: "Snow showers", icon: "weather_snowy" };
    if (value >= 95)
      return { description: "Thunderstorm", icon: "thunderstorm" };
    return { description: "Unknown", icon: "cloud" };
  }

  function getJson(url, generation, callback) {
    const request = new XMLHttpRequest();
    request.onreadystatechange = function() {
      if (request.readyState !== XMLHttpRequest.DONE || generation !== root.requestGeneration)
        return;
      if (request.status < 200 || request.status >= 300) {
        root.loading = false;
        root.error = "Weather service is unavailable";
        return;
      }
      try {
        callback(JSON.parse(request.responseText));
      } catch (e) {
        root.loading = false;
        root.error = "Weather response could not be read";
      }
    };
    request.open("GET", url);
    request.send();
  }

  function reload(force) {
    if (!active || loading || (!force && !isStale()))
      return;

    loading = true;
    error = "";
    const generation = ++requestGeneration;
    const query = encodeURIComponent(Settings.dashboard.weatherLocation || "Ho Chi Minh City");
    const geocodeUrl = "https://geocoding-api.open-meteo.com/v1/search?name=" + query + "&count=1&language=en&format=json";
    getJson(geocodeUrl, generation, function(geocode) {
      if (!geocode.results || geocode.results.length === 0) {
        root.loading = false;
        root.error = "Location not found";
        return;
      }
      const place = geocode.results[0];
      root.locationName = place.name + (place.country ? ", " + place.country : "");
      const params = "current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m" +
        "&hourly=weather_code,temperature_2m,precipitation_probability" +
        "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset" +
        "&timezone=auto&forecast_days=7";
      const forecastUrl = "https://api.open-meteo.com/v1/forecast?latitude=" + place.latitude + "&longitude=" + place.longitude + "&" + params;
      root.getJson(forecastUrl, generation, function(data) {
        root.current = data.current || {};
        root.timezone = data.timezone || "";
        const hours = [];
        const hourlyData = data.hourly || {};
        const times = hourlyData.time || [];
        const currentTime = String((data.current || {}).time || "");
        let startIndex = times.findIndex(time => String(time) >= currentTime);
        if (startIndex < 0)
          startIndex = 0;
        for (let i = startIndex; i < Math.min(startIndex + 24, times.length); i++) {
          const info = root.weatherInfo((hourlyData.weather_code || [])[i], 1);
          hours.push({
            time: hourlyData.time[i], temperature: (hourlyData.temperature_2m || [])[i],
            precipitation: (hourlyData.precipitation_probability || [])[i], icon: info.icon
          });
        }
        root.hourly = hours;
        const days = [];
        const dailyData = data.daily || {};
        for (let i = 0; i < (dailyData.time || []).length; i++) {
          const info = root.weatherInfo((dailyData.weather_code || [])[i], 1);
          days.push({
            date: dailyData.time[i], high: (dailyData.temperature_2m_max || [])[i],
            low: (dailyData.temperature_2m_min || [])[i], sunrise: (dailyData.sunrise || [])[i],
            sunset: (dailyData.sunset || [])[i], icon: info.icon, description: info.description
          });
        }
        root.daily = days;
        root.lastUpdated = Date.now();
        root.loading = false;
      });
    });
  }

  onActiveChanged: {
    if (active && isStale())
      reload(false);
  }

  Connections {
    target: Settings.dashboard
    function onWeatherLocationChanged() {
      root.requestGeneration++;
      root.loading = false;
      root.lastUpdated = 0;
      if (root.active)
        root.reload(true);
    }
  }

  Timer {
    interval: root.refreshInterval
    repeat: true
    running: root.active
    onTriggered: root.reload(false)
  }
}
