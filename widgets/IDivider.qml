import QtQuick
import qs.services

Rectangle {
  id: root
  property string orientation: "horizontal"

  width: orientation === "vertical" ? 2 : parent.width
  height: orientation === "vertical" ? parent.height : 2

  gradient: Gradient {
    orientation: root.orientation === "vertical" ? Gradient.Vertical : Gradient.Horizontal
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
