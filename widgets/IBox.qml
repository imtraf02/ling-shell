import QtQuick
import qs.commons
import qs.services

Rectangle {
  id: root

  color: ThemeService.palette.mSurfaceContainer
  border.color: Qt.alpha(ThemeService.palette.mOutline, 0.2)
  border.width: 1
  radius: Settings.appearance.cornerRadius
}
