import QtQuick
import QtQuick.Controls
import qs.widgets

Flickable {
  id: root

  rebound: Transition {
    IAnim {
      properties: "x,y"
    }
  }

  ScrollBar.vertical: IScrollBar {
    flickable: root
  }
}
