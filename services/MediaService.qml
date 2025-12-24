pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.commons

Singleton {
  id: root

  property var currentPlayer: null
  property real currentPosition: 0
  property bool isSeeking: false
  property int selectedPlayerIndex: 0
  property bool isPlaying: currentPlayer ? (currentPlayer.playbackState === MprisPlaybackState.Playing || currentPlayer.isPlaying) : false
  property string trackTitle: currentPlayer ? (currentPlayer.trackTitle !== undefined ? currentPlayer.trackTitle.replace(/(\r\n|\n|\r)/g, "") : "") : ""
  property string trackArtist: currentPlayer ? (currentPlayer.trackArtist || "") : ""
  property string trackAlbum: currentPlayer ? (currentPlayer.trackAlbum || "") : ""
  property string trackArtUrl: currentPlayer ? (currentPlayer.trackArtUrl || "") : ""
  property real trackLength: currentPlayer ? ((currentPlayer.length < infiniteTrackLength) ? currentPlayer.length : 0) : 0

  property bool canPlay: currentPlayer ? currentPlayer.canPlay : false
  property bool canPause: currentPlayer ? currentPlayer.canPause : false
  property bool canGoNext: currentPlayer ? currentPlayer.canGoNext : false
  property bool canGoPrevious: currentPlayer ? currentPlayer.canGoPrevious : false
  property bool canSeek: currentPlayer ? currentPlayer.canSeek : false
  property real infiniteTrackLength: 922337203685

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
        currentPosition = currentPlayer ? currentPlayer.position : 0;
      }
    }
  }

  function updateCurrentPlayer() {
    let newPlayer = findActivePlayer();
    if (newPlayer !== currentPlayer) {
      currentPlayer = newPlayer;
      currentPosition = currentPlayer ? currentPlayer.position : 0;
    }
  }

  function playPause() {
    if (currentPlayer) {
      let stateSource = currentPlayer._stateSource || currentPlayer;
      let controlTarget = currentPlayer._controlTarget || currentPlayer;
      if (stateSource.playbackState === MprisPlaybackState.Playing) {
        controlTarget.pause();
      } else {
        controlTarget.play();
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
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null;
    if (target && target.canSeek) {
      target.position = position;
      currentPosition = position;
    }
  }

  function seekByRatio(ratio) {
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null;
    if (target && target.canSeek && target.length > 0) {
      let seekPosition = ratio * target.length;
      target.position = seekPosition;
      currentPosition = seekPosition;
    }
  }

  Timer {
    id: positionTimer
    interval: 1000
    running: currentPlayer && !root.isSeeking && currentPlayer.isPlaying && currentPlayer.length > 0 && currentPlayer.playbackState === MprisPlaybackState.Playing
    repeat: true
    onTriggered: {
      if (currentPlayer && !root.isSeeking && currentPlayer.isPlaying && currentPlayer.playbackState === MprisPlaybackState.Playing) {
        currentPosition = currentPlayer.position;
      } else {
        running = false;
      }
    }
  }

  Connections {
    target: currentPlayer
    function onPositionChanged() {
      if (!root.isSeeking && currentPlayer) {
        currentPosition = currentPlayer.position;
      }
    }
    function onPlaybackStateChanged() {
      if (!root.isSeeking && currentPlayer) {
        currentPosition = currentPlayer.position;
      }
    }
  }

  onCurrentPlayerChanged: {
    if (!currentPlayer || !currentPlayer.isPlaying || currentPlayer.playbackState !== MprisPlaybackState.Playing) {
      currentPosition = 0;
    }
  }

  Timer {
    id: playerStateMonitor
    interval: 2000
    repeat: true
    running: true
    onTriggered: {
      if (autoSwitchingPaused)
        return;
      if (!currentPlayer || !currentPlayer.isPlaying || currentPlayer.playbackState !== MprisPlaybackState.Playing) {
        updateCurrentPlayer();
      }
    }
  }

  Connections {
    target: Mpris.players
    function onValuesChanged() {
      updateCurrentPlayer();
    }
  }
}
