pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.commons
import qs.widgets
import qs.services
import ".."

BarPanel {
  id: root

  property string panelViewMode: "wifi"

  property bool ethernetInfoExpanded: false
  property bool ethernetDetailsGrid: true

  property string passwordSsid: ""
  property string expandedSsid: ""
  property bool hasHadNetworks: false

  property string editingDnsIface: ""
  property string dnsInput: ""

  onPanelViewModeChanged: {
    // Reset transient states to avoid layout artifacts
    passwordSsid = "";
    expandedSsid = "";
    if (panelViewMode === "wifi") {
      ethernetInfoExpanded = false;
      // Trigger scan if needed
      if (Settings.network.wifiEnabled && !NetworkService.scanning && Object.keys(NetworkService.networks).length === 0)
        NetworkService.scan();
    } else {
      if (NetworkService.ethernetConnected) {
        NetworkService.refreshActiveEthernetDetails();
      } else {
        NetworkService.refreshEthernet();
      }
    }
  }

  onOpened: {
    hasHadNetworks = false;
    NetworkService.scan();
    // Preload active Wi‑Fi details so Info shows instantly
    NetworkService.refreshActiveWifiDetails();
    // Also fetch Ethernet details if connected
    NetworkService.refreshActiveEthernetDetails();

    // Restore last view logic (based on availability)
    if (!Settings.network.wifiEnabled && NetworkService.hasEthernet())
      panelViewMode = "ethernet";
    else
      panelViewMode = "wifi";
  }

  readonly property var knownNetworks: {
    if (!Settings.network.wifiEnabled)
      return [];

    let nets = Object.values(NetworkService.networks);
    let known = nets.filter(n => n.connected || n.existing || n.cached);

    // Sort: connected first, then by signal strength
    known.sort((a, b) => {
      if (a.connected !== b.connected)
        return b.connected - a.connected;
      return b.signal - a.signal;
    });

    return known;
  }

  readonly property var availableNetworks: {
    if (!Settings.network.wifiEnabled)
      return [];

    let nets = Object.values(NetworkService.networks);
    let available = nets.filter(n => !n.connected && !n.existing && !n.cached);

    // Sort by signal strength
    available.sort((a, b) => b.signal - a.signal);

    return available;
  }

  onKnownNetworksChanged: {
    if (knownNetworks.length > 0)
      hasHadNetworks = true;
  }

  onAvailableNetworksChanged: {
    if (availableNetworks.length > 0)
      hasHadNetworks = true;
  }

  contentComponent: Item {
    id: content
    implicitWidth: Style.bar.networkWidth
    implicitHeight: mainColumn.implicitHeight + (root.padding * 2)

    ColumnLayout {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: root.padding
      spacing: root.spacing

      IBox {
        id: headerBox
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + (root.padding * 2)

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: root.padding
          spacing: root.spacing

          IIcon {
            id: modeIcon
            icon: panelViewMode === "wifi" ? (Settings.network.wifiEnabled ? "wifi" : "wifi_off") : (NetworkService.hasEthernet() ? (NetworkService.ethernetConnected ? "ethernet" : "ethernet") : "ethernet_off")
            pointSize: Style.appearance.font.size.large
            color: panelViewMode === "wifi" ? (Settings.network.wifiEnabled ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurfaceVariant) : (NetworkService.ethernetConnected ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurfaceVariant)

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onClicked: {
                if (panelViewMode === "wifi") {
                  if (NetworkService.hasEthernet()) {
                    panelViewMode = "ethernet";
                  }
                } else {
                  panelViewMode = "wifi";
                }
              }
            }
          }

          IText {
            text: panelViewMode === "wifi" ? "Wi-Fi" : "Ethernet"
            pointSize: Style.appearance.font.size.larger
            font.weight: Font.DemiBold
            color: ThemeService.palette.mOnSurface
            Layout.fillWidth: true
          }

          ISwitch {
            id: wifiSwitch
            visible: panelViewMode === "wifi"
            checked: Settings.network.wifiEnabled
            onToggled: NetworkService.setWifiEnabled(checked)
          }

          IIconButton {
            icon: "refresh"
            size: Style.appearance.widget.size * 0.8
            enabled: panelViewMode === "wifi" ? (Settings.network.wifiEnabled && !NetworkService.scanning) : true
            onClicked: {
              if (panelViewMode === "wifi")
                NetworkService.scan();
              else
                NetworkService.refreshEthernet();
            }
          }

          IIconButton {
            icon: "close"
            size: Style.appearance.widget.size * 0.8
            onClicked: root.close()
          }
        }
      }

      // Unified scrollable content (Wi‑Fi or Ethernet view)
      ColumnLayout {
        id: wifiSectionContainer
        visible: true
        Layout.fillWidth: true
        spacing: root.spacing

        // Mode switch
        ITabBar {
          id: modeTabBar
          Layout.fillWidth: true
          currentIndex: root.panelViewMode === "wifi" ? 0 : 1

          content: [
            ITabButton {
              text: "Wi-Fi"
              tabIndex: 0
              checked: modeTabBar.currentIndex === 0
              onClicked: root.panelViewMode = "wifi"
            },
            ITabButton {
              // Dim when no Ethernet devices are detected
              opacity: NetworkService.hasEthernet() ? 1.0 : 0.5
              text: "Ethernet"
              tabIndex: 1
              checked: modeTabBar.currentIndex === 1
              onClicked: {
                if (NetworkService.hasEthernet()) {
                  root.panelViewMode = "ethernet";
                } else {
                  // Revert if no ethernet
                  modeTabBar.currentIndex = 0;
                }
              }
            }
          ]
        }

        // Error message
        Rectangle {
          visible: panelViewMode === "wifi" && NetworkService.lastError.length > 0
          Layout.fillWidth: true
          implicitHeight: errorRow.implicitHeight + (root.padding * 2)
          color: Qt.alpha(ThemeService.palette.mError, 0.1)
          radius: Settings.appearance.cornerRadius
          border.width: 2
          border.color: ThemeService.palette.mError

          RowLayout {
            id: errorRow
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: root.spacing

            IIcon {
              icon: "warning"
              pointSize: Style.appearance.font.size.large
              color: ThemeService.palette.mError
            }

            IText {
              text: NetworkService.lastError
              color: ThemeService.palette.mError
              pointSize: Style.appearance.font.size.small
              wrapMode: Text.Wrap
              Layout.fillWidth: true
            }

            IIconButton {
              icon: "close"
              size: Style.appearance.widget.size * 0.6
              onClicked: NetworkService.lastError = ""
            }
          }
        }

        // Unified scrollable content
        IFlickable {
          id: contentScroll
          Layout.fillWidth: true
          Layout.preferredHeight: Math.min(contentColumn.implicitHeight, 380)
          Layout.fillHeight: false
          clip: true
          contentWidth: parent.width
          contentHeight: contentColumn.implicitHeight

          ColumnLayout {
            id: contentColumn
            width: contentScroll.width
            spacing: root.spacing

            // Wi‑Fi disabled state
            IBox {
              id: disabledBox
              visible: panelViewMode === "wifi" && !Settings.network.wifiEnabled
              Layout.fillWidth: true
              implicitHeight: disabledColumn.implicitHeight + root.padding * 2

              ColumnLayout {
                id: disabledColumn
                anchors.fill: parent
                anchors.margins: root.padding

                Item {
                  Layout.fillHeight: true
                }

                IIcon {
                  icon: "wifi_off"
                  pointSize: 48
                  color: ThemeService.palette.mOnSurfaceVariant
                  Layout.alignment: Qt.AlignHCenter
                }

                IText {
                  text: "Wi-Fi is disabled"
                  pointSize: Style.appearance.font.size.large
                  color: ThemeService.palette.mOnSurfaceVariant
                  Layout.alignment: Qt.AlignHCenter
                }

                IText {
                  text: "Enable Wi-Fi to connect to networks"
                  pointSize: Style.appearance.font.size.small
                  color: ThemeService.palette.mOnSurfaceVariant
                  horizontalAlignment: Text.AlignHCenter
                  Layout.fillWidth: true
                  wrapMode: Text.WordWrap
                }

                Item {
                  Layout.fillHeight: true
                }
              }
            }

            // Scanning state
            IBox {
              id: scanningBox
              visible: panelViewMode === "wifi" && Settings.network.wifiEnabled && Object.keys(NetworkService.networks).length === 0 && !root.hasHadNetworks
              Layout.fillWidth: true
              implicitHeight: scanningColumn.implicitHeight + root.padding * 2

              ColumnLayout {
                id: scanningColumn
                anchors.fill: parent
                anchors.margins: root.padding
                spacing: root.spacing * 2

                Item {
                  Layout.fillHeight: true
                }

                IBusyIndicator {
                  running: true
                  color: ThemeService.palette.mPrimary
                  size: Style.appearance.widget.size
                  Layout.alignment: Qt.AlignHCenter
                }

                IText {
                  text: "Searching for nearby networks..."
                  pointSize: Style.appearance.font.size.normal
                  color: ThemeService.palette.mOnSurfaceVariant
                  Layout.alignment: Qt.AlignHCenter
                }

                Item {
                  Layout.fillHeight: true
                }
              }
            }

            // Empty state
            IBox {
              id: emptyBox
              visible: panelViewMode === "wifi" && Settings.network.wifiEnabled && !NetworkService.scanning && Object.keys(NetworkService.networks).length === 0 && root.hasHadNetworks
              Layout.fillWidth: true
              implicitHeight: emptyColumn.implicitHeight + root.padding * 2

              ColumnLayout {
                id: emptyColumn
                anchors.fill: parent
                anchors.margins: root.padding
                spacing: root.spacing * 2

                Item {
                  Layout.fillHeight: true
                }

                IIcon {
                  icon: "search"
                  pointSize: 64
                  color: ThemeService.palette.mOnSurfaceVariant
                  Layout.alignment: Qt.AlignHCenter
                }

                IText {
                  text: "No networks found"
                  pointSize: Style.appearance.font.size.large
                  color: ThemeService.palette.mOnSurfaceVariant
                  Layout.alignment: Qt.AlignHCenter
                }

                IButton {
                  text: "Scan again"
                  icon: "refresh"
                  Layout.alignment: Qt.AlignHCenter
                  onClicked: NetworkService.scan()
                }

                Item {
                  Layout.fillHeight: true
                }
              }
            }

            // Networks list container (Wi‑Fi)
            ColumnLayout {
              id: networksList
              visible: panelViewMode === "wifi" && Settings.network.wifiEnabled && Object.keys(NetworkService.networks).length > 0
              width: parent.width
              spacing: root.spacing

              WiFiNetworksList {
                label: "Known Networks"
                model: root.knownNetworks
                passwordSsid: root.passwordSsid
                expandedSsid: root.expandedSsid
                onDnsEditRequested: (iface, currentDns) => {
                  root.dnsInput = currentDns;
                  root.editingDnsIface = iface;
                }
                onDnsEditCancelled: {
                  root.editingDnsIface = "";
                  root.dnsInput = "";
                }
                onDnsEditSaved: (iface, dns) => {
                  NetworkService.setDns(iface, dns);
                  root.editingDnsIface = "";
                  root.dnsInput = "";
                }
                editingDnsIface: root.editingDnsIface
                dnsInput: root.dnsInput
              }

              WiFiNetworksList {
                label: "Available Networks"
                model: root.availableNetworks
                passwordSsid: root.passwordSsid
                expandedSsid: root.expandedSsid
                onPasswordRequested: ssid => {
                  root.passwordSsid = ssid;
                  root.expandedSsid = "";
                }
                onPasswordSubmitted: (ssid, password) => {
                  NetworkService.connect(ssid, password);
                  root.passwordSsid = "";
                }
                onPasswordCancelled: root.passwordSsid = ""
                onDnsEditRequested: (iface, currentDns) => {
                  root.dnsInput = currentDns;
                  root.editingDnsIface = iface;
                }
                onDnsEditCancelled: {
                  root.editingDnsIface = "";
                  root.dnsInput = "";
                }
                onDnsEditSaved: (iface, dns) => {
                  NetworkService.setDns(iface, dns);
                  root.editingDnsIface = "";
                  root.dnsInput = "";
                }
                editingDnsIface: root.editingDnsIface
                dnsInput: root.dnsInput
              }
            }

            // Ethernet view
            ColumnLayout {
              id: ethernetSection
              visible: panelViewMode === "ethernet"
              width: parent.width
              spacing: root.spacing

              IText {
                text: "Available Interfaces"
                pointSize: Style.appearance.font.size.normal
                color: ThemeService.palette.mOnSurface
              }

              // Empty state when no Ethernet devices
              IBox {
                visible: !(NetworkService.ethernetInterfaces && NetworkService.ethernetInterfaces.length > 0)
                Layout.fillWidth: true
                implicitHeight: emptyEthColumn.implicitHeight + root.padding * 2

                ColumnLayout {
                  id: emptyEthColumn
                  anchors.fill: parent
                  anchors.margins: root.padding
                  spacing: root.padding

                  IIcon {
                    icon: "ethernet_off"
                    pointSize: 40
                    color: ThemeService.palette.mOnSurfaceVariant
                    Layout.alignment: Qt.AlignHCenter
                  }

                  IText {
                    text: "No Ethernet devices detected"
                    pointSize: Style.appearance.font.size.small
                    color: ThemeService.palette.mOnSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                  }
                }
              }

              // Interfaces list
              ColumnLayout {
                id: ethIfacesList
                visible: NetworkService.ethernetInterfaces && NetworkService.ethernetInterfaces.length > 0
                width: parent.width
                spacing: Style.appearance.spacing.small

                Repeater {
                  model: NetworkService.ethernetInterfaces || []
                  delegate: IBox {
                    id: ethItem

                    Layout.fillWidth: true
                    // Layout.leftMargin: Style.appearance.spacing.small
                    // Layout.rightMargin: Style.appearance.spacing.small
                    implicitHeight: ethItemColumn.implicitHeight + (root.padding * 2)
                    radius: Settings.appearance.cornerRadius
                    border.width: 1 // Style.borderS
                    border.color: modelData.connected ? ThemeService.palette.mPrimary : ThemeService.palette.mOutline
                    color: modelData.connected ? Qt.rgba(ThemeService.palette.mPrimary.r, ThemeService.palette.mPrimary.g, ThemeService.palette.mPrimary.b, 0.05) : ThemeService.palette.mSurface

                    ColumnLayout {
                      id: ethItemColumn
                      width: parent.width - (root.padding * 2)
                      x: root.padding
                      y: root.padding
                      spacing: root.spacing

                      // Main row
                      RowLayout {
                        id: ethHeaderRow
                        Layout.fillWidth: true
                        spacing: root.spacing

                        IIcon {
                          icon: "ethernet"
                          pointSize: Style.appearance.font.size.large
                          color: modelData.connected ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurface
                        }

                        ColumnLayout {
                          Layout.fillWidth: true
                          spacing: 2

                          IText {
                            text: modelData.ifname
                            pointSize: Style.appearance.font.size.normal
                            font.weight: modelData.connected ? Font.DemiBold : Font.Medium
                            color: ThemeService.palette.mOnSurface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                          }

                          RowLayout {
                            spacing: Style.appearance.spacing.small

                            // Connected badge
                            Rectangle {
                              visible: modelData.connected
                              color: ThemeService.palette.mPrimary
                              radius: height * 0.5
                              width: ethConnectedText.implicitWidth + (Style.appearance.spacing.small * 2)
                              height: ethConnectedText.implicitHeight + (Style.appearance.spacing.small * 0.5)

                              IText {
                                id: ethConnectedText
                                anchors.centerIn: parent
                                text: "Connected"
                                pointSize: Style.appearance.font.size.smaller
                                color: ThemeService.palette.mOnPrimary
                              }
                            }
                          }
                        }

                        IIconButton {
                          icon: "info"
                          size: Style.appearance.widget.size * 0.7
                          enabled: true
                          onClicked: {
                            if (NetworkService.activeEthernetIf === modelData.ifname && ethernetInfoExpanded) {
                              ethernetInfoExpanded = false;
                              return;
                            }
                            if (NetworkService.activeEthernetIf !== modelData.ifname) {
                              NetworkService.activeEthernetIf = modelData.ifname;
                              NetworkService.activeEthernetDetailsTimestamp = 0;
                            }
                            ethernetInfoExpanded = true;
                            NetworkService.refreshActiveEthernetDetails();
                          }
                        }
                      }

                      // Tap handling
                      TapHandler {
                        target: ethHeaderRow
                        onTapped: {
                          if (NetworkService.activeEthernetIf === modelData.ifname && ethernetInfoExpanded) {
                            ethernetInfoExpanded = false;
                            return;
                          }
                          if (NetworkService.activeEthernetIf !== modelData.ifname) {
                            NetworkService.activeEthernetIf = modelData.ifname;
                            NetworkService.activeEthernetDetailsTimestamp = 0;
                          }
                          ethernetInfoExpanded = true;
                          NetworkService.refreshActiveEthernetDetails();
                        }
                      }

                      // Inline Ethernet details
                      Rectangle {
                        id: ethInfoInline
                        visible: ethernetInfoExpanded && NetworkService.activeEthernetIf === modelData.ifname
                        Layout.fillWidth: true
                        color: ThemeService.palette.mSurfaceVariant
                        radius: Settings.appearance.cornerRadius
                        border.width: 1
                        border.color: ThemeService.palette.mOutline
                        implicitHeight: ethInfoGrid.implicitHeight + root.padding * 2
                        clip: true
                        Layout.topMargin: Style.appearance.spacing.small

                        // Grid/List toggle
                        IIconButton {
                          anchors.top: parent.top
                          anchors.right: parent.right
                          anchors.margins: Style.appearance.spacing.small
                          icon: ethernetDetailsGrid ? "view_list" : "grid_view"
                          size: Style.appearance.widget.size * 0.6
                          onClicked: ethernetDetailsGrid = !ethernetDetailsGrid
                          z: 1
                        }

                        GridLayout {
                          id: ethInfoGrid
                          anchors.fill: parent
                          anchors.margins: Style.appearance.spacing.small
                          anchors.rightMargin: Style.appearance.widget.size
                          columns: ethernetDetailsGrid ? 2 : 1
                          columnSpacing: root.spacing
                          rowSpacing: Style.appearance.spacing.small

                          // Interface name
                          RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.appearance.spacing.small
                            IIcon {
                              icon: "ethernet"
                              pointSize: Style.appearance.font.size.small
                              color: ThemeService.palette.mOnSurface
                              // Layout.alignment: Qt.AlignVCenter
                            }
                            IText {
                              text: (NetworkService.activeEthernetDetails.ifname && NetworkService.activeEthernetDetails.ifname.length > 0) ? NetworkService.activeEthernetDetails.ifname : (NetworkService.activeEthernetIf || "-")
                              pointSize: Style.appearance.font.size.small
                              color: ThemeService.palette.mOnSurface
                              Layout.fillWidth: true
                              wrapMode: ethernetDetailsGrid ? Text.NoWrap : Text.WrapAtWordBoundaryOrAnywhere
                              elide: ethernetDetailsGrid ? Text.ElideRight : Text.ElideNone
                              maximumLineCount: ethernetDetailsGrid ? 1 : 6
                              clip: true

                              MouseArea {
                                anchors.fill: parent
                                enabled: ((NetworkService.activeEthernetDetails.ifname || "").length > 0) || ((NetworkService.activeEthernetIf || "").length > 0)
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                  const value = (NetworkService.activeEthernetDetails.ifname && NetworkService.activeEthernetDetails.ifname.length > 0) ? NetworkService.activeEthernetDetails.ifname : (NetworkService.activeEthernetIf || "");
                                  if (value.length > 0) {
                                    Quickshell.execDetached(["wl-copy", value]);
                                  }
                                }
                              }
                            }
                          }

                          // Internet connectivity
                          RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.appearance.spacing.small
                            IIcon {
                              icon: modelData.connected ? (NetworkService.internetConnectivity ? "public" : "public_off") : "public_off"
                              pointSize: Style.appearance.font.size.small
                              color: modelData.connected ? (NetworkService.internetConnectivity ? ThemeService.palette.mOnSurface : ThemeService.palette.mError) : ThemeService.palette.mError
                            }
                            IText {
                              text: modelData.connected ? (NetworkService.internetConnectivity ? "Internet Connected" : "Limited Connection") : "Disconnected"
                              pointSize: Style.appearance.font.size.small
                              color: modelData.connected ? (NetworkService.internetConnectivity ? ThemeService.palette.mOnSurface : ThemeService.palette.mError) : ThemeService.palette.mError
                              Layout.fillWidth: true
                              wrapMode: ethernetDetailsGrid ? Text.NoWrap : Text.WrapAtWordBoundaryOrAnywhere
                              elide: ethernetDetailsGrid ? Text.ElideRight : Text.ElideNone
                              maximumLineCount: ethernetDetailsGrid ? 1 : 6
                              clip: true
                            }
                          }

                          // Link speed
                          RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.appearance.spacing.small
                            IIcon {
                              icon: "speed"
                              pointSize: Style.appearance.font.size.small
                              color: ThemeService.palette.mOnSurface
                            }
                            IText {
                              text: (NetworkService.activeEthernetDetails.speed && NetworkService.activeEthernetDetails.speed.length > 0) ? NetworkService.activeEthernetDetails.speed : "-"
                              pointSize: Style.appearance.font.size.small
                              color: ThemeService.palette.mOnSurface
                              Layout.fillWidth: true
                              wrapMode: ethernetDetailsGrid ? Text.NoWrap : Text.WrapAtWordBoundaryOrAnywhere
                              elide: ethernetDetailsGrid ? Text.ElideRight : Text.ElideNone
                              maximumLineCount: ethernetDetailsGrid ? 1 : 6
                              clip: true
                            }
                          }

                          // IPv4 address
                          RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.appearance.spacing.small
                            IIcon {
                              icon: "lan"
                              pointSize: Style.appearance.font.size.small
                              color: ThemeService.palette.mOnSurface
                            }
                            IText {
                              text: NetworkService.activeEthernetDetails.ipv4 || "-"
                              pointSize: Style.appearance.font.size.small
                              color: ThemeService.palette.mOnSurface
                              Layout.fillWidth: true
                              wrapMode: ethernetDetailsGrid ? Text.NoWrap : Text.WrapAtWordBoundaryOrAnywhere
                              elide: ethernetDetailsGrid ? Text.ElideRight : Text.ElideNone
                              maximumLineCount: ethernetDetailsGrid ? 1 : 6
                              clip: true

                              MouseArea {
                                anchors.fill: parent
                                enabled: (NetworkService.activeEthernetDetails.ipv4 || "").length > 0
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                  const value = NetworkService.activeEthernetDetails.ipv4 || "";
                                  if (value.length > 0) {
                                    Quickshell.execDetached(["wl-copy", value]);
                                  }
                                }
                              }
                            }
                          }

                          // Gateway
                          RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.appearance.spacing.small
                            IIcon {
                              icon: "router"
                              pointSize: Style.appearance.font.size.small
                              color: ThemeService.palette.mOnSurface
                            }
                            IText {
                              text: NetworkService.activeEthernetDetails.gateway4 || "-"
                              pointSize: Style.appearance.font.size.small
                              color: ThemeService.palette.mOnSurface
                              Layout.fillWidth: true
                              wrapMode: ethernetDetailsGrid ? Text.NoWrap : Text.WrapAtWordBoundaryOrAnywhere
                              elide: ethernetDetailsGrid ? Text.ElideRight : Text.ElideNone
                              maximumLineCount: ethernetDetailsGrid ? 1 : 6
                              clip: true
                            }
                          }

                          // DNS
                          RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.appearance.spacing.small
                            IIcon {
                              icon: "dns"
                              pointSize: Style.appearance.font.size.small
                              color: ThemeService.palette.mOnSurface
                            }

                            ColumnLayout {
                              Layout.fillWidth: true
                              spacing: 2
                              visible: root.editingDnsIface === modelData.ifname

                              Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 32
                                radius: 4
                                color: ThemeService.palette.mSurface
                                border.color: dnsEditInput.activeFocus ? ThemeService.palette.mPrimary : ThemeService.palette.mOutline
                                border.width: 1

                                TextInput {
                                  id: dnsEditInput
                                  anchors.fill: parent
                                  anchors.margins: 4
                                  text: root.dnsInput
                                  font.pointSize: Style.appearance.font.size.small
                                  color: ThemeService.palette.mOnSurface
                                  onTextChanged: root.dnsInput = text
                                  focus: visible
                                }
                              }

                              RowLayout {
                                spacing: 8
                                IButton {
                                  text: "Save"
                                  fontSize: Style.appearance.font.size.smaller
                                  onClicked: {
                                    NetworkService.setDns(modelData.ifname, root.dnsInput);
                                    root.editingDnsIface = "";
                                  }
                                }
                                IButton {
                                  text: "Cancel"
                                  fontSize: Style.appearance.font.size.smaller
                                  outlined: true
                                  onClicked: root.editingDnsIface = ""
                                }
                              }
                            }

                            IText {
                              visible: root.editingDnsIface !== modelData.ifname
                              text: NetworkService.activeEthernetDetails.dns || "-"
                              pointSize: Style.appearance.font.size.small
                              color: ThemeService.palette.mOnSurface
                              Layout.fillWidth: true
                              wrapMode: ethernetDetailsGrid ? Text.NoWrap : Text.WrapAtWordBoundaryOrAnywhere
                              elide: ethernetDetailsGrid ? Text.ElideRight : Text.ElideNone
                              maximumLineCount: ethernetDetailsGrid ? 1 : 6
                              clip: true
                            }

                            IIconButton {
                              visible: root.editingDnsIface !== modelData.ifname && modelData.connected
                              icon: "edit"
                              size: 24
                              onClicked: {
                                root.dnsInput = NetworkService.activeEthernetDetails.dns || "";
                                root.editingDnsIface = modelData.ifname;
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
