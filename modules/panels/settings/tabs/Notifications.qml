import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

ColumnLayout {
  spacing: Style.spacing.normal
  SettingsPage {
    title: "Notifications"
    description: "Delivery, expiry, grouping, and gesture behavior."
    icon: "notifications"
    sectionId: "notifications"
    SettingsCardGrid {
      id: grid
      SettingsCard {
        title: "Notification preview"
        description: "A local sample of your configured notification style."
        icon: "notifications_active"
        Layout.columnSpan: grid.columns
        IBox {
          Layout.fillWidth: true; implicitHeight: 88; color: ThemeService.palette.mSurfaceVariant
          RowLayout {
            anchors.fill: parent; anchors.margins: Style.padding.normal
            IIcon { icon: "notifications"; color: ThemeService.palette.mPrimary; font.pointSize: Style.font.size.extraLarge }
            ColumnLayout {
              Layout.fillWidth: true
              IText { text: Settings.notifications.enabled ? "Settings updated" : "Notifications disabled"; font.weight: Font.Medium }
              IText { text: Settings.notifications.expire ? "Expires after " + Settings.notifications.defaultExpireTimeout + " ms" : "Stays until dismissed"; color: ThemeService.palette.mOnSurfaceVariant; font.pointSize: Style.font.size.small }
            }
          }
        }
      }
      SettingsCard {
        title: "Delivery"
        description: "When notifications appear and expire."
        icon: "send"
        IToggle { label: "Enable notifications"; checked: Settings.notifications.enabled; onToggled: checked => Settings.notifications.enabled = checked }
        IToggle { label: "Expire notifications"; checked: Settings.notifications.expire; onToggled: checked => Settings.notifications.expire = checked }
        SettingsSpinRow { label: "Default timeout"; value: Settings.notifications.defaultExpireTimeout; from: 1000; to: 60000; stepSize: 500; suffix: " ms"; enabled: Settings.notifications.expire; onChanged: value => Settings.notifications.defaultExpireTimeout = value }
        IToggle { label: "Run action on click"; checked: Settings.notifications.actionOnClick; onToggled: checked => Settings.notifications.actionOnClick = checked }
      }
      SettingsCard {
        title: "Grouping & gestures"
        description: "Preview count and swipe distance."
        icon: "swipe"
        SettingsSpinRow { label: "Group preview count"; value: Settings.notifications.groupPreviewNum; from: 1; to: 20; onChanged: value => Settings.notifications.groupPreviewNum = value }
        SettingsSpinRow { label: "Clear threshold"; value: Settings.notifications.clearThreshold; from: 0.05; to: 1; stepSize: 0.05; onChanged: value => Settings.notifications.clearThreshold = value }
        SettingsSpinRow { label: "Expand threshold"; value: Settings.notifications.expandThreshold; from: 1; to: 200; suffix: " px"; onChanged: value => Settings.notifications.expandThreshold = value }
      }
      SettingsCard {
        title: "History retention"
        description: "Bound notification history so background memory cannot grow indefinitely."
        icon: "history"
        SettingsSpinRow { label: "Maximum entries"; description: "Oldest entries are removed first."; value: Settings.notifications.historyLimit; from: 10; to: 500; stepSize: 10; onChanged: value => Settings.notifications.historyLimit = value }
        SettingsSpinRow { label: "Retention period"; description: "Entries older than this are removed automatically."; value: Settings.notifications.historyRetentionDays; from: 1; to: 365; suffix: " days"; onChanged: value => Settings.notifications.historyRetentionDays = value }
      }
    }
  }
}
