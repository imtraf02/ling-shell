pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets
import qs.services
import ".."

BarPanel {
  id: root

  contentComponent: Item {
    id: content

    implicitWidth: Config.bar.sizes.calendarWidth
    implicitHeight: calendar.implicitHeight + root.padding * 2

    IBox {
      id: calendar

      property int month: TimeService.date.getMonth()
      property int year: TimeService.date.getFullYear()

      function getDaysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
      }

      function getFirstDayOfMonth(year, month) {
        return new Date(year, month, 1).getDay();
      }

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.margins: root.padding
      implicitHeight: inner.implicitHeight + inner.anchors.margins * 2

      property var daysModel: {
        const firstOfMonth = new Date(year, month, 1);
        const lastOfMonth = new Date(year, month + 1, 0);
        const daysInMonth = lastOfMonth.getDate();
        const today = TimeService.date;

        const firstDayOfWeek = Qt.locale().firstDayOfWeek;
        const firstOfMonthDayOfWeek = firstOfMonth.getDay();
        let daysBefore = (firstOfMonthDayOfWeek - firstDayOfWeek + 7) % 7;
        const lastOfMonthDayOfWeek = lastOfMonth.getDay();
        const daysAfter = (firstDayOfWeek - lastOfMonthDayOfWeek - 1 + 7) % 7;

        const days = [];

        const prevMonth = new Date(year, month, 0);
        const prevMonthDays = prevMonth.getDate();
        for (let i = daysBefore - 1; i >= 0; i--) {
          const day = prevMonthDays - i;
          const date = new Date(year, month - 1, day);
          days.push({
            "day": day,
            "month": month - 1,
            "year": month === 0 ? year - 1 : year,
            "today": false,
            "currentMonth": false,
            "date": date
          });
        }

        for (let day = 1; day <= daysInMonth; day++) {
          const date = new Date(year, month, day);
          const isToday = date.getFullYear() === today.getFullYear() && date.getMonth() === today.getMonth() && date.getDate() === today.getDate();
          days.push({
            "day": day,
            "month": month,
            "year": year,
            "today": isToday,
            "currentMonth": true,
            "date": date
          });
        }

        for (let i = 1; i <= daysAfter; i++) {
          const date = new Date(year, month + 1, i);
          days.push({
            "day": i,
            "month": month + 1,
            "year": month === 11 ? year + 1 : year,
            "today": false,
            "currentMonth": false,
            "date": date
          });
        }

        return days;
      }

      ColumnLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: root.padding
        spacing: root.spacing

        RowLayout {
          Layout.fillWidth: true
          spacing: root.spacing

          Item {
            implicitWidth: implicitHeight
            implicitHeight: prevMonthText.implicitHeight + root.spacing * 2

            IIconButton {
              id: prevMonthText
              anchors.centerIn: parent
              icon: "chevron_left"

              onClicked: {
                let newDate = new Date(calendar.year, calendar.month - 1, 1);
                calendar.year = newDate.getFullYear();
                calendar.month = newDate.getMonth();
              }
            }
          }

          Item {
            Layout.fillWidth: true
            implicitWidth: monthYearDisplay.implicitWidth + root.spacing * 2
            implicitHeight: monthYearDisplay.implicitHeight + root.spacing * 2

            IText {
              id: monthYearDisplay
              anchors.centerIn: parent
              text: Qt.locale().monthName(calendar.month, Locale.LongFormat) + " " + calendar.year
              color: ThemeService.palette.mPrimary
              pointSize: Config.appearance.font.size.normal
              font.weight: 500
              font.capitalization: Font.Capitalize
            }
          }

          Item {
            implicitWidth: implicitHeight
            implicitHeight: nextMonthText.implicitHeight + root.spacing * 2

            IIconButton {
              id: nextMonthText
              anchors.centerIn: parent
              icon: "chevron_right"

              onClicked: {
                let newDate = new Date(calendar.year, calendar.month + 1, 1);
                calendar.year = newDate.getFullYear();
                calendar.month = newDate.getMonth();
              }
            }
          }
        }

        GridLayout {
          Layout.fillWidth: true
          columns: 7
          columnSpacing: 3
          rowSpacing: 0

          Repeater {
            model: 7
            delegate: Item {
              required property int index

              Layout.fillWidth: true
              Layout.preferredHeight: dayNameText.implicitHeight + root.spacing

              property int dayIndex: (Qt.locale().firstDayOfWeek + index) % 7

              IText {
                id: dayNameText
                anchors.centerIn: parent
                text: Qt.locale().dayName(parent.dayIndex, Locale.ShortFormat)
                horizontalAlignment: Text.AlignHCenter
                font.weight: 500
                color: (parent.dayIndex === 0 || parent.dayIndex === 6) ? ThemeService.palette.mSecondary : ThemeService.palette.mOnSurfaceVariant
              }
            }
          }
        }

        Item {
          Layout.fillWidth: true
          implicitHeight: grid.implicitHeight

          GridLayout {
            id: grid
            anchors.fill: parent
            columns: 7
            columnSpacing: 3
            rowSpacing: 3

            Repeater {
              model: calendar.daysModel

              delegate: Item {
                id: dayItem
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: width

                Rectangle {
                  id: dayBackground

                  width: Math.min(parent.width, parent.height)
                  height: width
                  anchors.centerIn: parent
                  radius: Config.appearance.rounding.full
                  color: parent.modelData.today ? ThemeService.palette.mPrimary : "transparent"

                  Behavior on color {
                    ColorAnimation {
                      duration: 200
                    }
                  }

                  IText {
                    anchors.centerIn: parent
                    text: dayItem.modelData.day
                    color: {
                      if (dayItem.modelData.today)
                        return ThemeService.palette.mOnPrimary;

                      const dayOfWeek = dayItem.modelData.date.getDay();

                      if (dayOfWeek === 0 || dayOfWeek === 6)
                        return ThemeService.palette.mSecondary;

                      return ThemeService.palette.mOnSurfaceVariant;
                    }
                    opacity: dayItem.modelData.currentMonth ? 1.0 : 0.4
                    pointSize: Config.appearance.font.size.normal
                    font.weight: dayItem.modelData.today ? 600 : 500
                  }
                }
              }
            }
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton

        onWheel: event => {
          const delta = event.angleDelta.y > 0 ? -1 : event.angleDelta.y < 0 ? 1 : 0;
          if (delta !== 0) {
            let newDate = new Date(calendar.year, calendar.month + delta, 1);
            calendar.year = newDate.getFullYear();
            calendar.month = newDate.getMonth();
          }
        }
      }
    }
  }
}
