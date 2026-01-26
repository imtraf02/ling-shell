import QtQuick
import Quickshell
import qs.common
import qs.services

Item {
  id: root

  property ShellScreen screen

  property Component panelContent
  property bool closeWithEscape: true
  property bool exclusiveKeyboard: true

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

  function toggle() {
    isPanelOpen ? close() : open();
  }

  function open() {
    PanelService.closedImmediately = false;
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

  opacity: isClosing || (isPanelVisible && sizeAnimationComplete) ? 1.0 : 0.0

  onOpacityChanged: {
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

      property bool dimensionsInitialized: false

      readonly property real currentWidth: targetWidth
      readonly property real currentHeight: root.isClosing ? 0 : (root.isPanelVisible ? targetHeight : 0)

      property int topLeftCornerState: 0
      property int topRightCornerState: 0
      property int bottomLeftCornerState: (y + height >= root.height - 1) ? 1 : 0
      property int bottomRightCornerState: (y + height >= root.height - 1) ? 1 : 0

      width: currentWidth
      height: currentHeight
      anchors.horizontalCenter: parent.horizontalCenter // Use anchors for centering
      y: root.height - height

      Behavior on width {
        enabled: !PanelService.closedImmediately && panelBackground.dimensionsInitialized
        NumberAnimation {
          duration: {
            if (root.sizeAnimationComplete)
              return Style.anim.durations.small;
            return root.isOpening ? Style.anim.durations.normal : root.isClosing ? Style.anim.durations.small : Style.anim.durations.normal;
          }
          easing.type: Easing.BezierSpline
          easing.bezierCurve: Style.anim.curves.emphasizedDecel
        }
      }

      Behavior on height {
        enabled: !PanelService.closedImmediately
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
              if (root.isClosing && panelBackground.height === 0) {
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
}
