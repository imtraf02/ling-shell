import QtQuick
import qs.widgets

ListView {
  id: root

  maximumFlickVelocity: 3000

  rebound: Transition {
    IAnim {
      properties: "x,y"
    }
  }
}
