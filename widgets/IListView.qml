import QtQuick

ListView {
  id: root

  maximumFlickVelocity: 3000

  rebound: Transition {
    IAnim {
      properties: "x,y"
    }
  }
}
