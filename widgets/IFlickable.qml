import QtQuick
import QtQuick.Controls

Flickable {
  id: root

  maximumFlickVelocity: 3000

  rebound: Transition {
    IAnim {
      properties: "x,y"
    }
  }

  ScrollBar.vertical: IScrollBar {
    flickable: root
  }
}
