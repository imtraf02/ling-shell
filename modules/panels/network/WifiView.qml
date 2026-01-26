pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets
import qs.modules.panels.network

ColumnLayout {
  id: root

  property string passwordSsid: ""
  property string expandedSsid: ""
  property bool hasHadNetworks: false

  readonly property var knownNetworks: {
    if (!Settings.network.wifiEnabled)
      return [];
    const nets = Object.values(NetworkService.networks);
    const known = nets.filter(n => n.connected || n.existing || n.cached);
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
    const nets = Object.values(NetworkService.networks);
    const available = nets.filter(n => !n.connected && !n.existing && !n.cached);
    available.sort((a, b) => b.signal - a.signal);
    return available;
  }

  onKnownNetworksChanged: if (knownNetworks.length > 0)
    hasHadNetworks = true
  onAvailableNetworksChanged: if (availableNetworks.length > 0)
    hasHadNetworks = true

  Component.onCompleted: {
    if (Settings.network.wifiEnabled && !NetworkService.scanning && Object.keys(NetworkService.networks).length === 0)
      NetworkService.scan();

    if (knownNetworks.length > 0 || availableNetworks.length > 0) {
      hasHadNetworks = true;
    }
  }

  anchors.margins: Style.padding.small
  spacing: Style.spacing.small

  // Wi-Fi Disabled State
  IIcon {
    visible: !Settings.network.wifiEnabled
    icon: "signal_wifi_off"
    font.pointSize: 48
    color: ThemeService.palette.mOnSurfaceVariant
    Layout.alignment: Qt.AlignHCenter
  }

  IText {
    visible: !Settings.network.wifiEnabled
    text: "Wi-Fi is disabled"
    font.pointSize: Style.font.size.large
    color: ThemeService.palette.mOnSurfaceVariant
    Layout.alignment: Qt.AlignHCenter
  }

  IText {
    visible: !Settings.network.wifiEnabled
    text: "Enable Wi-Fi to scan for networks"
    font.pointSize: Style.font.size.small
    color: ThemeService.palette.mOnSurfaceVariant
    horizontalAlignment: Text.AlignHCenter
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
  }

  // Scanning State
  IBusyIndicator {
    visible: Settings.network.wifiEnabled && Object.keys(NetworkService.networks).length === 0 && !root.hasHadNetworks
    running: visible
    color: ThemeService.palette.mPrimary
    size: Style.widget.size * 0.8
    Layout.alignment: Qt.AlignHCenter
  }

  IText {
    visible: Settings.network.wifiEnabled && Object.keys(NetworkService.networks).length === 0 && !root.hasHadNetworks
    text: "Searching for networks..."
    font.pointSize: Style.font.size.normal
    color: ThemeService.palette.mOnSurfaceVariant
    Layout.alignment: Qt.AlignHCenter
  }

  // Empty State
  IIcon {
    visible: Settings.network.wifiEnabled && !NetworkService.scanning && Object.keys(NetworkService.networks).length === 0 && root.hasHadNetworks

    icon: "search"
    font.pointSize: 64
    color: ThemeService.palette.mOnSurfaceVariant
    Layout.alignment: Qt.AlignHCenter
  }

  IText {
    visible: Settings.network.wifiEnabled && !NetworkService.scanning && Object.keys(NetworkService.networks).length === 0 && root.hasHadNetworks

    text: "No networks found"
    font.pointSize: Style.font.size.large
    color: ThemeService.palette.mOnSurfaceVariant
    Layout.alignment: Qt.AlignHCenter
  }

  IButton {
    visible: Settings.network.wifiEnabled && !NetworkService.scanning && Object.keys(NetworkService.networks).length === 0 && root.hasHadNetworks

    text: "Scan Again"
    icon: "refresh"
    Layout.alignment: Qt.AlignHCenter
    onClicked: NetworkService.scan()
  }

  // Networks Lists
  WiFiNetworksList {
    visible: Settings.network.wifiEnabled && Object.keys(NetworkService.networks).length > 0
    Layout.fillWidth: true
    label: "Known Networks"
    model: root.knownNetworks
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
    onForgetRequested: ssid => root.expandedSsid = root.expandedSsid === ssid ? "" : ssid
    onForgetConfirmed: ssid => {
      NetworkService.forget(ssid);
      root.expandedSsid = "";
    }
    onForgetCancelled: root.expandedSsid = ""
  }

  WiFiNetworksList {
    visible: Settings.network.wifiEnabled && Object.keys(NetworkService.networks).length > 0
    Layout.fillWidth: true
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
    onForgetRequested: ssid => root.expandedSsid = root.expandedSsid === ssid ? "" : ssid
    onForgetConfirmed: ssid => {
      NetworkService.forget(ssid);
      root.expandedSsid = "";
    }
    onForgetCancelled: root.expandedSsid = ""
  }
}
