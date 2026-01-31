pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets
import qs.modules.panels.network

ColumnLayout {
  id: root

  property string selectedSsid: ""
  property string passwordSsid: ""
  property string expandedSsid: ""
  property bool hasHadNetworks: false

  readonly property var allNetworks: {
    if (!Settings.network.wifiEnabled)
      return [];

    const nets = Object.values(NetworkService.networks);
    nets.sort((a, b) => {
      if (a.connected !== b.connected)
        return b.connected - a.connected;

      const aSaved = a.existing || a.cached;
      const bSaved = b.existing || b.cached;

      if (aSaved !== bSaved)
        return bSaved - aSaved;

      return b.signal - a.signal;
    });
    return nets;
  }

  anchors.margins: Style.padding.small
  spacing: Style.spacing.small

  Component.onCompleted: {
    if (Settings.network.wifiEnabled && !NetworkService.scanning && Object.keys(NetworkService.networks).length === 0)
      NetworkService.scan();

    if (allNetworks.length > 0) {
      hasHadNetworks = true;
      selectedSsid = allNetworks[0].ssid;
    }
  }

  onAllNetworksChanged: {
    if (allNetworks.length > 0) {
      hasHadNetworks = true;
      if (!selectedSsid)
        selectedSsid = allNetworks[0].ssid;
    }
  }

  // Wi-Fi Disabled State
  ColumnLayout {
    visible: !Settings.network.wifiEnabled
    spacing: Style.spacing.small
    Layout.alignment: Qt.AlignHCenter

    IIcon {
      icon: "signal_wifi_off"
      font.pointSize: Style.font.size.extraLarge
      color: ThemeService.palette.mOnSurfaceVariant
      Layout.alignment: Qt.AlignHCenter
    }

    IText {
      text: "Wi-Fi is disabled"
      font.pointSize: Style.font.size.large
      color: ThemeService.palette.mOnSurfaceVariant
      Layout.alignment: Qt.AlignHCenter
    }

    IText {
      text: "Enable Wi-Fi to scan for networks"
      font.pointSize: Style.font.size.small
      color: ThemeService.palette.mOnSurfaceVariant
      horizontalAlignment: Text.AlignHCenter
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
    }
  }

  // Scanning State
  ColumnLayout {
    visible: Settings.network.wifiEnabled && Object.keys(NetworkService.networks).length === 0 && !root.hasHadNetworks
    spacing: Style.spacing.small
    Layout.alignment: Qt.AlignHCenter

    IBusyIndicator {
      running: true
      color: ThemeService.palette.mPrimary
      size: Style.widget.size * 0.8
      Layout.alignment: Qt.AlignHCenter
    }

    IText {
      text: "Searching for networks..."
      font.pointSize: Style.font.size.normal
      color: ThemeService.palette.mOnSurfaceVariant
      Layout.alignment: Qt.AlignHCenter
    }
  }

  // Empty State
  ColumnLayout {
    visible: Settings.network.wifiEnabled && !NetworkService.scanning && Object.keys(NetworkService.networks).length === 0 && root.hasHadNetworks
    spacing: Style.spacing.small
    Layout.alignment: Qt.AlignHCenter

    IIcon {
      icon: "search"
      font.pointSize: Style.font.size.extraLarge
      color: ThemeService.palette.mOnSurfaceVariant
      Layout.alignment: Qt.AlignHCenter
    }

    IText {
      text: "No networks found"
      font.pointSize: Style.font.size.large
      color: ThemeService.palette.mOnSurfaceVariant
      Layout.alignment: Qt.AlignHCenter
    }

    IButton {
      text: "Scan Again"
      icon: "refresh"
      Layout.alignment: Qt.AlignHCenter
      onClicked: NetworkService.scan()
    }
  }

  // Networks List
  WiFiNetworksList {
    visible: Settings.network.wifiEnabled && Object.keys(NetworkService.networks).length > 0
    Layout.fillWidth: true
    model: root.allNetworks
    passwordSsid: root.passwordSsid
    expandedSsid: root.expandedSsid
    selectedSsid: root.selectedSsid
    onSelectedRequested: ssid => root.selectedSsid = (root.selectedSsid === ssid ? "" : ssid)
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
