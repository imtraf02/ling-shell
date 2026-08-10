import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

IBox {
  id: root

  property int month: TimeService.date.getMonth()
  property int year: TimeService.date.getFullYear()
  readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
  readonly property var weekdayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

  function getDaysInMonth(year, month) {
    return new Date(year, month + 1, 0).getDate();
  }

  function getFirstDayOfMonth(year, month) {
    return new Date(year, month, 1).getDay();
  }

  implicitHeight: inner.implicitHeight + inner.anchors.margins * 2

  property var daysModel: {
    const firstOfMonth = new Date(year, month, 1);
    const lastOfMonth = new Date(year, month + 1, 0);
    const daysInMonth = lastOfMonth.getDate();
    const today = TimeService.date;

    const firstDayOfWeek = 0;
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
    anchors.margins: Style.padding.normal
    spacing: Style.spacing.small

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.spacing.small

      Item {
        implicitWidth: implicitHeight
        implicitHeight: prevMonthText.implicitHeight + Style.spacing.small * 2

        IIconButton {
          id: prevMonthText
          anchors.centerIn: parent
          icon: "chevron_left"

          onClicked: {
            let newDate = new Date(root.year, root.month - 1, 1);
            root.year = newDate.getFullYear();
            root.month = newDate.getMonth();
          }
        }
      }

      Item {
        Layout.fillWidth: true
        implicitWidth: monthYearDisplay.implicitWidth + Style.spacing.small * 2
        implicitHeight: monthYearDisplay.implicitHeight + Style.spacing.small * 2

        IText {
          id: monthYearDisplay
          anchors.centerIn: parent
          text: root.monthNames[root.month] + " " + root.year
          color: ThemeService.palette.mPrimary
          font.pointSize: Style.font.size.normal
          font.weight: 500
          font.capitalization: Font.Capitalize
        }
      }

      Item {
        implicitWidth: implicitHeight
        implicitHeight: nextMonthText.implicitHeight + Style.spacing.small * 2

        IIconButton {
          id: nextMonthText
          anchors.centerIn: parent
          icon: "chevron_right"

          onClicked: {
            let newDate = new Date(root.year, root.month + 1, 1);
            root.year = newDate.getFullYear();
            root.month = newDate.getMonth();
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
          Layout.preferredHeight: dayNameText.implicitHeight + Style.spacing.small

          property int dayIndex: index

          IText {
            id: dayNameText
            anchors.centerIn: parent
            text: root.weekdayNames[parent.dayIndex]
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
          model: root.daysModel

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
              radius: Style.rounding.full
              color: parent.modelData.today ? ThemeService.palette.mPrimary : "transparent"

              Behavior on color {
                ICAnim {}
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
                font.pointSize: Style.font.size.normal
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
        let newDate = new Date(root.year, root.month + delta, 1);
        root.year = newDate.getFullYear();
        root.month = newDate.getMonth();
      }
    }
  }
}
