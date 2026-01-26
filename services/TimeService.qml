pragma Singleton

import QtQuick
import Quickshell

Singleton {
  property alias enabled: clock.enabled
  readonly property date date: clock.date
  readonly property int hours: clock.hours
  readonly property int minutes: clock.minutes
  readonly property int seconds: clock.seconds

  function format(fmt: string): string {
    return Qt.formatDateTime(clock.date, fmt);
  }

  function formatVagueHumanReadableDuration(totalSeconds) {
    if (typeof totalSeconds !== 'number' || totalSeconds < 0) {
      return '0s';
    }

    // Floor the input to handle decimal seconds
    totalSeconds = Math.floor(totalSeconds);

    const days = Math.floor(totalSeconds / 86400);
    const hours = Math.floor((totalSeconds % 86400) / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;

    const parts = [];
    if (days)
      parts.push(`${days}d`);
    if (hours)
      parts.push(`${hours}h`);
    if (minutes)
      parts.push(`${minutes}m`);

    // Only show seconds if no hours and no minutes
    if (!hours && !minutes) {
      parts.push(`${seconds}s`);
    }

    return parts.join(' ');
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }
}
