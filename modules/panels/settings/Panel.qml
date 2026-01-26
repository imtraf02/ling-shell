pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.panels
import qs.common
import qs.widgets
import qs.services

SmartPanel {
  id: root

  position: "top"
  anchor: "center"

  enum Tab {
    About,
    Bar,
    Personalization
  }

  property int currentTabIndex: 0
  property var tabsModel: []
  property var _content: null

  onOpened: {
    if (_content) {
      _content.initialize();
    }
  }

  panelContent: Content {
    id: content

    readonly property real contentPreferredWidth: Style.settings.width
    readonly property real contentPreferredHeight: Style.settings.height

    onCloseRequested: root.close()
    Component.onCompleted: {
      root._content = content;
    }
  }
}
