pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.common

Singleton {
  id: root

  property var currentPlayer: null
  readonly property var statePlayer: currentPlayer ? (currentPlayer._stateSource || currentPlayer) : null
  readonly property var controlPlayer: currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null
  property real currentPosition: 0
  property bool isSeeking: false
  property int selectedPlayerIndex: 0
  property bool isPlaying: statePlayer ? (statePlayer.playbackState === MprisPlaybackState.Playing || statePlayer.isPlaying) : false
  property string trackTitle: statePlayer ? (statePlayer.trackTitle !== undefined ? statePlayer.trackTitle.replace(/(\r\n|\n|\r)/g, "") : "") : ""
  property string trackArtist: statePlayer ? (statePlayer.trackArtist || "") : ""
  property string trackAlbum: statePlayer ? (statePlayer.trackAlbum || "") : ""
  property string trackArtUrl: statePlayer ? (statePlayer.trackArtUrl || "") : ""
  property real trackLength: 0

  property bool canPlay: controlPlayer ? controlPlayer.canPlay : false
  property bool canPause: controlPlayer ? controlPlayer.canPause : false
  property bool canGoNext: controlPlayer ? controlPlayer.canGoNext : false
  property bool canGoPrevious: controlPlayer ? controlPlayer.canGoPrevious : false
  property bool canSeek: statePlayer ? statePlayer.canSeek : false
  property real infiniteTrackLength: 922337203685

  function sourceTrackLength() {
    if (!statePlayer)
      return 0;
    if (statePlayer.lengthSupported === false)
      return 0;
    const value = Number(statePlayer.length);
    return isFinite(value) && value > 0 && value < infiniteTrackLength ? value : 0;
  }

  function refreshTrackLength(allowDecrease) {
    const candidate = sourceTrackLength();
    if (candidate <= 0) {
      if (allowDecrease || (statePlayer && statePlayer.lengthSupported === false))
        trackLength = 0;
      return;
    }
    if (allowDecrease || trackLength <= 0 || candidate > trackLength)
      trackLength = candidate;
  }

  Component.onCompleted: {
    updateCurrentPlayer();
  }

  function getAvailablePlayers() {
    if (!Mpris.players || !Mpris.players.values) {
      return [];
    }

    let allPlayers = Mpris.players.values;
    let finalPlayers = [];
    const genericBrowsers = ["firefox", "chromium", "chrome"];
    const blacklist = (Settings.audio && Settings.audio.mprisBlacklist) ? Settings.audio.mprisBlacklist : [];

    let specificPlayers = [];
    let genericPlayers = [];

    for (var i = 0; i < allPlayers.length; i++) {
      const identity = String(allPlayers[i].identity || "").toLowerCase();
      const match = blacklist.find(b => {
        const s = String(b || "").toLowerCase();
        return s && identity.includes(s);
      });
      if (match)
        continue;
      if (genericBrowsers.some(b => identity.includes(b))) {
        genericPlayers.push(allPlayers[i]);
      } else {
        specificPlayers.push(allPlayers[i]);
      }
    }

    let matchedGenericIndices = {};

    for (var i = 0; i < specificPlayers.length; i++) {
      let specificPlayer = specificPlayers[i];
      let title1 = String(specificPlayer.trackTitle || "").trim();
      let wasMatched = false;

      if (title1) {
        for (var j = 0; j < genericPlayers.length; j++) {
          if (matchedGenericIndices[j])
            continue;
          let genericPlayer = genericPlayers[j];
          let title2 = String(genericPlayer.trackTitle || "").trim();

          if (title2 && (title1.includes(title2) || title2.includes(title1))) {
            let dataPlayer = genericPlayer;
            let identityPlayer = specificPlayer;

            let scoreSpecific = (specificPlayer.trackArtUrl ? 1 : 0);
            let scoreGeneric = (genericPlayer.trackArtUrl ? 1 : 0);
            if (scoreSpecific > scoreGeneric) {
              dataPlayer = specificPlayer;
            }

            let virtualPlayer = {
              "identity": identityPlayer.identity,
              "desktopEntry": identityPlayer.desktopEntry,
              "trackTitle": dataPlayer.trackTitle,
              "trackArtist": dataPlayer.trackArtist,
              "trackAlbum": dataPlayer.trackAlbum,
              "trackArtUrl": dataPlayer.trackArtUrl,
              "length": dataPlayer.length || 0,
              "position": dataPlayer.position || 0,
              "playbackState": dataPlayer.playbackState,
              "isPlaying": dataPlayer.isPlaying || false,
              "canPlay": dataPlayer.canPlay || false,
              "canPause": dataPlayer.canPause || false,
              "canGoNext": dataPlayer.canGoNext || false,
              "canGoPrevious": dataPlayer.canGoPrevious || false,
              "canSeek": dataPlayer.canSeek || false,
              "canControl": dataPlayer.canControl || false,
              "_stateSource": dataPlayer,
              "_controlTarget": identityPlayer
            };
            finalPlayers.push(virtualPlayer);
            matchedGenericIndices[j] = true;
            wasMatched = true;
            break;
          }
        }
      }
      if (!wasMatched) {
        finalPlayers.push(specificPlayer);
      }
    }

    for (var i = 0; i < genericPlayers.length; i++) {
      if (!matchedGenericIndices[i]) {
        finalPlayers.push(genericPlayers[i]);
      }
    }

    let controllablePlayers = [];
    for (var i = 0; i < finalPlayers.length; i++) {
      let player = finalPlayers[i];
      if (player && player.canControl) {
        controllablePlayers.push(player);
      }
    }
    return controllablePlayers;
  }

  function findActivePlayer() {
    let availablePlayers = getAvailablePlayers();
    if (availablePlayers.length === 0) {
      return null;
    }

    for (var i = 0; i < availablePlayers.length; i++) {
      if (availablePlayers[i] && availablePlayers[i].playbackState === MprisPlaybackState.Playing) {
        selectedPlayerIndex = i;
        return availablePlayers[i];
      }
    }

    const preferred = (Settings.audio.preferredPlayer || "");
    if (preferred !== "") {
      for (var i = 0; i < availablePlayers.length; i++) {
        const p = availablePlayers[i];
        const identity = String(p.identity || "").toLowerCase();
        const pref = preferred.toLowerCase();
        if (identity.includes(pref)) {
          selectedPlayerIndex = i;
          return p;
        }
      }
    }

    if (selectedPlayerIndex < availablePlayers.length) {
      return availablePlayers[selectedPlayerIndex];
    } else {
      selectedPlayerIndex = 0;
      return availablePlayers[0];
    }
  }

  property bool autoSwitchingPaused: false

  function switchToPlayer(index) {
    let availablePlayers = getAvailablePlayers();
    if (index >= 0 && index < availablePlayers.length) {
      let newPlayer = availablePlayers[index];
      if (newPlayer !== currentPlayer) {
        currentPlayer = newPlayer;
        selectedPlayerIndex = index;
        currentPosition = statePlayer ? statePlayer.position : 0;
      }
    }
  }

  function updateCurrentPlayer() {
    let newPlayer = findActivePlayer();
    if (newPlayer !== currentPlayer) {
      currentPlayer = newPlayer;
      currentPosition = statePlayer ? statePlayer.position : 0;
    }
  }

  function playPause() {
    if (statePlayer && controlPlayer) {
      if (statePlayer.playbackState === MprisPlaybackState.Playing) {
        controlPlayer.pause();
      } else {
        controlPlayer.play();
      }
    }
  }

  function play() {
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null;
    if (target && target.canPlay) {
      target.play();
    }
  }

  function stop() {
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null;
    if (target) {
      target.stop();
    }
  }

  function pause() {
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null;
    if (target && target.canPause) {
      target.pause();
    }
  }

  function next() {
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null;
    if (target && target.canGoNext) {
      target.next();
    }
  }

  function previous() {
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null;
    if (target && target.canGoPrevious) {
      target.previous();
    }
  }

  function seek(position) {
    const target = statePlayer;
    if (target && target.canSeek) {
      const maximum = trackLength > 0 ? trackLength : sourceTrackLength();
      const boundedPosition = Math.max(0, maximum > 0 ? Math.min(maximum, position) : position);
      target.position = boundedPosition;
      currentPosition = boundedPosition;
    }
  }

  function seekByRatio(ratio) {
    const target = statePlayer;
    if (target && target.canSeek && trackLength > 0) {
      const boundedRatio = Math.max(0, Math.min(1, Number(ratio) || 0));
      seek(boundedRatio * trackLength);
    }
  }

  function seekRelative(seconds) {
    const target = statePlayer;
    if (!target || !target.canSeek)
      return;
    const sourcePosition = Number(target.position);
    const basePosition = isFinite(sourcePosition) ? sourcePosition : currentPosition;
    seek(basePosition + seconds);
  }

  Timer {
    id: positionTimer
    interval: 1000
    running: statePlayer && !root.isSeeking && root.isPlaying && statePlayer.length > 0
    repeat: true
    onTriggered: {
      if (statePlayer && !root.isSeeking && root.isPlaying) {
        currentPosition = statePlayer.position;
      } else {
        running = false;
      }
    }
  }

  Connections {
    target: statePlayer
    function onPositionChanged() {
      if (!root.isSeeking && statePlayer) {
        currentPosition = statePlayer.position;
      }
    }
    function onPlaybackStateChanged() {
      if (!root.isSeeking && statePlayer) {
        currentPosition = statePlayer.position;
      }
      if (!autoSwitchingPaused)
        Qt.callLater(root.updateCurrentPlayer);
    }
    function onLengthChanged() {
      root.refreshTrackLength(false);
    }
    function onLengthSupportedChanged() {
      root.refreshTrackLength(true);
    }
    function onTrackChanged() {
      root.trackLength = 0;
      Qt.callLater(() => root.refreshTrackLength(true));
    }
  }

  onCurrentPlayerChanged: {
    if (!statePlayer || !isPlaying) {
      currentPosition = 0;
    }
  }

  onStatePlayerChanged: {
    trackLength = 0;
    refreshTrackLength(true);
    if (!root.isSeeking)
      currentPosition = statePlayer ? statePlayer.position : 0;
  }

  Connections {
    target: Mpris.players
    function onValuesChanged() {
      updateCurrentPlayer();
    }
  }
}
