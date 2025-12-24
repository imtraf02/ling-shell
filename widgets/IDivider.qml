import QtQuick
import qs.services

Rectangle {
  width: parent.width
  height: 2
  gradient: Gradient {
    orientation: Gradient.Horizontal
    GradientStop {
      position: 0.0
      color: "transparent"
    }
    GradientStop {
      position: 0.1
      color: Qt.alpha(ThemeService.palette.mOutline, 0.4)
    }
    GradientStop {
      position: 0.9
      color: Qt.alpha(ThemeService.palette.mOutline, 0.4)
    }
    GradientStop {
      position: 1.0
      color: "transparent"
    }
  }
}
