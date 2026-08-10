import QtQuick
import Quickshell
import qs.common
import qs.services
import qs.widgets

Item {
  id: root

  // Panel position: "top", "left", "right", "bottom"
  property string position: "top"

  // Alignment along the edge: "start", "center", "end"
  property string anchor: "center"

  // Offset in pixels (positive moves right/down)
  property real offset: 0

  property ShellScreen screen
  property Component panelContent
  property bool closeWithEscape: true
  property bool exclusiveKeyboard: true
  // Top/bottom panels normally animate only their edge-facing dimension.
  // Opt in when a panel changes width with its current content.
  property bool animateContentWidth: false

  // Button positioning (for BarPanel behavior)
  property var buttonItem: null
  property bool useButtonPosition: false
  property point buttonPosition: Qt.point(0, 0)
  property int buttonWidth: 0
  property int buttonHeight: 0

  property bool isPanelOpen: false
  property bool isPanelVisible: false
  property bool sizeAnimationComplete: false
  readonly property bool isOpening: isPanelVisible && !isClosing && !sizeAnimationComplete
  property bool isClosing: false

  // Internal state tracking
  property bool _opacityFadeComplete: false
  property bool _closeFinalized: false
  property bool _closeWatchdogActive: false
  property bool _openWatchdogActive: false

  // Computed properties for animation direction
  readonly property bool _animateWidth: position === "left" || position === "right"
  readonly property bool _animateHeight: position === "top" || position === "bottom"

  readonly property var panelRegion: panelContent.geometryPlaceholder

  signal opened
  signal closed

  visible: isPanelVisible
  width: parent ? parent.width : 0
  height: parent ? parent.height : 0

  function onEscapePressed() {
    if (closeWithEscape)
      close();
  }

  function toggle(buttonItem, buttonName) {
    isPanelOpen ? close() : open(buttonItem, buttonName);
  }

  function open(buttonItem, buttonName) {
    PanelService.closedImmediately = false;

    if (position === "top" && !buttonItem && buttonName)
      return;

    if (position === "top" && buttonItem)
      _updateButtonPosition(buttonItem);

    isPanelOpen = true;
    PanelService.willOpenPanel(root);
  }

  function close() {
    PanelService.closedImmediately = false;
    isClosing = true;
    sizeAnimationComplete = false;
    _closeFinalized = false;

    opacityTrigger.stop();
    _openWatchdogActive = false;
    openWatchdogTimer.stop();

    _closeWatchdogActive = true;
    closeWatchdogTimer.restart();

    _opacityFadeComplete = (opacity === 0.0);
  }

  function closeImmediately() {
    opacityTrigger.stop();
    _openWatchdogActive = false;
    openWatchdogTimer.stop();
    _closeWatchdogActive = false;
    closeWatchdogTimer.stop();

    isPanelVisible = false;
    sizeAnimationComplete = false;
    isClosing = false;
    _opacityFadeComplete = false;
    _closeFinalized = true;
    isPanelOpen = false;
    panelBackground.dimensionsInitialized = false;

    PanelService.closedImmediately = true;
    PanelService.closedPanel(root);
    closed();
  }

  function _updateButtonPosition(item) {
    if (!item || typeof item.mapToItem !== "function") {
      buttonItem = null;
      useButtonPosition = false;
      return;
    }

    try {
      root.buttonItem = item;
      const pos = item.mapToItem(null, 0, 0);
      buttonPosition = Qt.point(pos.x, pos.y);
      buttonWidth = item.width;
      buttonHeight = item.height;
      useButtonPosition = true;
    } catch (e) {
      buttonItem = null;
      useButtonPosition = false;
    }
  }

  function _finalizeClose() {
    if (_closeFinalized)
      return;

    _closeFinalized = true;
    _closeWatchdogActive = false;
    closeWatchdogTimer.stop();

    isPanelVisible = false;
    isPanelOpen = false;
    isClosing = false;
    _opacityFadeComplete = false;
    panelBackground.dimensionsInitialized = false;

    PanelService.closedPanel(root);
    closed();
  }

  function setPosition() {
    if (!width || !height) {
      Qt.callLater(setPosition);
      return;
    }

    const content = contentLoader.item;

    panelBackground.targetWidth = Math.min(content.contentPreferredWidth, root.width);
    panelBackground.targetHeight = Math.min(content.contentPreferredHeight, root.height - Style.bar.innerHeight);

    // Calculate position based on panel type
    if (position === "top") {
      panelBackground.targetY = 0;
      if (useButtonPosition && width > 0 && panelBackground.targetWidth > 0) {
        const centerX = root.mapFromItem(null, root.buttonPosition.x, 0).x + root.buttonWidth / 2 - panelBackground.targetWidth / 2;
        panelBackground.targetX = Math.max(0, Math.min(centerX, width - panelBackground.targetWidth));
      }
    }
  }

  Connections {
    target: contentLoader.item
    ignoreUnknownSignals: true

    function onContentPreferredWidthChanged() {
      if (root.isPanelOpen && root.isPanelVisible)
        root.setPosition();
    }

    function onContentPreferredHeightChanged() {
      if (root.isPanelOpen && root.isPanelVisible)
        root.setPosition();
    }
  }

  opacity: {
    if (position === "top") {
      return isClosing ? 0.0 : (isPanelVisible && sizeAnimationComplete ? 1.0 : 0.0);
    } else {
      return isClosing || (isPanelVisible && sizeAnimationComplete) ? 1.0 : 0.0;
    }
  }

  Behavior on opacity {
    enabled: !PanelService.closedImmediately && position === "top"
    NumberAnimation {
      duration: Style.anim.durations.small
      easing.type: Easing.OutQuad
      easing.bezierCurve: root.isClosing ? Style.anim.curves.emphasized : Style.anim.curves.emphasizedDecel

      onRunningChanged: {
        if (running || duration === 0) {
          if (!running && duration === 0) {
            if (root.isClosing && root.opacity === 0.0) {
              root._opacityFadeComplete = true;
              const shouldFinalizeNow = !root.panelRegion?.shouldAnimateWidth && !root.panelRegion?.shouldAnimateHeight;
              if (shouldFinalizeNow)
                Qt.callLater(root._finalizeClose);
            } else if (root.isPanelVisible && root.opacity === 1.0) {
              root._openWatchdogActive = false;
              openWatchdogTimer.stop();
            }
          }
          return;
        }

        if (root.isClosing && root.opacity === 0.0) {
          root._opacityFadeComplete = true;
          const shouldFinalizeNow = !root.panelRegion?.shouldAnimateWidth && !root.panelRegion?.shouldAnimateHeight;
          if (shouldFinalizeNow)
            Qt.callLater(root._finalizeClose);
        } else if (root.isPanelVisible && root.opacity === 1.0) {
          root._openWatchdogActive = false;
          openWatchdogTimer.stop();
        }
      }
    }
  }

  onOpacityChanged: {
    if (position !== "top") {
      if (root.isClosing && root.opacity === 0.0) {
        root._opacityFadeComplete = true;
        const shouldFinalizeNow = !root.panelRegion?.shouldAnimateWidth && !root.panelRegion?.shouldAnimateHeight;
        if (shouldFinalizeNow)
          Qt.callLater(root._finalizeClose);
      } else if (root.isPanelVisible && root.opacity === 1.0) {
        root._openWatchdogActive = false;
        openWatchdogTimer.stop();
      }
    }
  }

  Timer {
    id: opacityTrigger
    interval: Style.anim.durations.normal * 0.5
    onTriggered: {
      if (root.isPanelVisible)
        root.sizeAnimationComplete = true;
    }
  }

  Timer {
    id: openWatchdogTimer
    interval: Style.anim.durations.normal * 3
    onTriggered: {
      if (root._openWatchdogActive && root.isPanelOpen && !root.isPanelVisible) {
        root._openWatchdogActive = false;
        root.isPanelVisible = true;
        root.sizeAnimationComplete = true;
      }
    }
  }

  Timer {
    id: closeWatchdogTimer
    interval: Style.anim.durations.small * 3
    onTriggered: {
      if (root._closeWatchdogActive && !root._closeFinalized) {
        Qt.callLater(root._finalizeClose);
      }
    }
  }

  Item {
    id: panelContent
    anchors.fill: parent

    property alias geometryPlaceholder: panelBackground

    Item {
      id: panelBackground

      readonly property var panelItem: panelBackground

      property real targetWidth: 0
      property real targetHeight: 0
      property real targetX: 0
      property real targetY: 0
      property bool dimensionsInitialized: false

      readonly property real currentWidth: {
        if (root._animateWidth) {
          return root.isClosing ? 0 : (root.isPanelVisible ? targetWidth : 0);
        }
        return targetWidth;
      }

      readonly property real currentHeight: {
        if (root._animateHeight) {
          return root.isClosing ? 0 : (root.isPanelVisible ? targetHeight : 0);
        }
        return targetHeight;
      }

      readonly property bool atTop: y <= 1
      readonly property bool atBottom: y + height >= root.height - 1
      readonly property bool atLeft: x <= 1
      readonly property bool atRight: x + width >= root.width - 1

      readonly property int topLeftCornerState: {
        if (atTop && atLeft)
          return (root.position === "left" || root.position === "right") ? 2 : 1;
        if (atTop)
          return 1;
        if (atLeft)
          return 2;
        return 0;
      }
      readonly property int topRightCornerState: {
        if (atTop && atRight)
          return (root.position === "left" || root.position === "right") ? 2 : 1;
        if (atTop)
          return 1;
        if (atRight)
          return 2;
        return 0;
      }
      readonly property int bottomLeftCornerState: {
        if (atBottom && atLeft)
          return (root.position === "left" || root.position === "right") ? 2 : 1;
        if (atBottom)
          return 1;
        if (atLeft)
          return 2;
        return 0;
      }
      readonly property int bottomRightCornerState: {
        if (atBottom && atRight)
          return (root.position === "left" || root.position === "right") ? 2 : 1;
        if (atBottom)
          return 1;
        if (atRight)
          return 2;
        return 0;
      }

      width: currentWidth
      height: currentHeight

      x: {
        // Special case for top panel attached to a button
        if (root.position === "top" && root.useButtonPosition) {
          return targetX;
        }

        if (root.position === "left")
          return 0;
        if (root.position === "right")
          return root.width - width;

        // Horizontal alignment (Top/Bottom)
        if (root.anchor === "center")
          return (root.width - width) / 2 + root.offset;
        if (root.anchor === "end")
          return root.width - width + root.offset;
        return 0 + root.offset; // start
      }

      y: {
        if (root.position === "top")
          return targetY;
        if (root.position === "bottom")
          return root.height - height;

        // Vertical alignment (Left/Right)
        if (root.anchor === "center")
          return (root.height - height) / 2 + root.offset;
        if (root.anchor === "end")
          return root.height - height + root.offset;
        return 0 + root.offset; // start
      }

      Behavior on width {
        enabled: !PanelService.closedImmediately && (root._animateWidth || (root.animateContentWidth && panelBackground.dimensionsInitialized))
        NumberAnimation {
          duration: {
            if (!panelBackground.dimensionsInitialized)
              return 0;
            if (root.sizeAnimationComplete)
              return Style.anim.durations.small;
            return root.isOpening ? Style.anim.durations.normal : root.isClosing ? Style.anim.durations.small : Style.anim.durations.normal;
          }
          easing.type: Easing.BezierSpline
          easing.bezierCurve: root.isClosing ? Style.anim.curves.emphasized : Style.anim.curves.emphasizedDecel

          onRunningChanged: {
            if (!running) {
              if (root.isClosing && panelBackground.width === 0 && root._animateWidth) {
                Qt.callLater(root._finalizeClose);
              }
            }
          }
        }
      }

      Behavior on height {
        enabled: !PanelService.closedImmediately && (root._animateHeight || panelBackground.dimensionsInitialized)
        NumberAnimation {
          duration: {
            if (!panelBackground.dimensionsInitialized && root._animateHeight)
              return 0;
            if (root.sizeAnimationComplete)
              return Style.anim.durations.small;
            return root.isOpening ? Style.anim.durations.normal : root.isClosing ? Style.anim.durations.small : Style.anim.durations.normal;
          }
          easing.type: Easing.BezierSpline
          easing.bezierCurve: root.isClosing ? Style.anim.curves.emphasized : Style.anim.curves.emphasizedDecel

          onRunningChanged: {
            if (!running) {
              if (root.isClosing && panelBackground.height === 0 && root._animateHeight) {
                Qt.callLater(root._finalizeClose);
              }
            }
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        z: -1
        onClicked: mouse => mouse.accepted = true
      }
    }

    Loader {
      id: contentLoader
      active: root.isPanelOpen
      x: panelBackground.x
      y: panelBackground.y
      width: panelBackground.width
      height: panelBackground.height
      clip: true

      sourceComponent: root.panelContent

      onLoaded: Qt.callLater(() => {
        root.setPosition();
        panelBackground.dimensionsInitialized = true;
        root.isPanelVisible = true;
        opacityTrigger.start();
        root._openWatchdogActive = true;
        openWatchdogTimer.start();
        root.opened();
      })
    }
  }

  Component.onCompleted: PanelService.registerPanel(root)
  Component.onDestruction: PanelService.unregisterPanel(root)
}
