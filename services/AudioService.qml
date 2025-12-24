pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.commons

Singleton {
  id: root
  readonly property PwNode sink: Pipewire.defaultAudioSink
  readonly property PwNode source: Pipewire.defaultAudioSource
  readonly property var nodes: Pipewire.nodes.values.reduce((acc, node) => {
    if (!node.isStream) {
      if (node.isSink) {
        acc.sinks.push(node);
      } else if (node.audio) {
        acc.sources.push(node);
      }
    }
    return acc;
  }, {
    "sources": [],
    "sinks": []
  })

  readonly property list<PwNode> sinks: nodes.sinks
  readonly property list<PwNode> sources: nodes.sources

  readonly property alias volume: root._volume
  property real _volume: Pipewire.defaultAudioSink?.audio?.volume ?? 0

  readonly property alias muted: root._muted
  property bool _muted: !!Pipewire.defaultAudioSink?.audio?.muted

  readonly property alias inputVolume: root._inputVolume
  property real _inputVolume: Pipewire.defaultAudioSource?.audio?.volume ?? 0

  readonly property alias inputMuted: root._inputMuted
  property bool _inputMuted: !!Pipewire.defaultAudioSource?.audio?.muted

  readonly property real stepVolume: Settings.audio.volumeStep / 100.0

  PwObjectTracker {
    objects: [...root.sinks, ...root.sources]
  }

  Connections {
    target: Pipewire.defaultAudioSink?.audio ?? null

    function onVolumeChanged() {
      const vol = Pipewire.defaultAudioSink?.audio?.volume ?? 0;
      if (!isNaN(vol)) {
        root._volume = vol;
      }
    }

    function onMutedChanged() {
      root._muted = !!Pipewire.defaultAudioSink?.audio?.muted;
    }
  }

  Connections {
    target: Pipewire.defaultAudioSource?.audio ?? null

    function onVolumeChanged() {
      const vol = Pipewire.defaultAudioSource?.audio?.volume ?? 0;
      if (!isNaN(vol)) {
        root._inputVolume = vol;
      }
    }

    function onMutedChanged() {
      root._inputMuted = !!Pipewire.defaultAudioSource?.audio?.muted;
    }
  }

  function increaseVolume() {
    setVolume(volume + stepVolume);
  }
  function decreaseVolume() {
    setVolume(volume - stepVolume);
  }

  function setVolume(newVolume) {
    const s = Pipewire.defaultAudioSink;
    if (s?.ready && s?.audio) {
      s.audio.muted = false;
      s.audio.volume = Math.max(0, Math.min(Settings.audio.volumeOverdrive ? 1.5 : 1.0, newVolume));
    }
  }

  function setOutputMuted(m) {
    const s = Pipewire.defaultAudioSink;
    if (s?.ready && s?.audio) {
      s.audio.muted = m;
    }
  }

  function increaseInputVolume() {
    setInputVolume(inputVolume + stepVolume);
  }
  function decreaseInputVolume() {
    setInputVolume(inputVolume - stepVolume);
  }

  function setInputVolume(newVolume) {
    const s = Pipewire.defaultAudioSource;
    if (s?.ready && s?.audio) {
      s.audio.muted = false;
      s.audio.volume = Math.max(0, Math.min(Settings.audio.volumeOverdrive ? 1.5 : 1.0, newVolume));
    }
  }

  function setInputMuted(m) {
    const s = Pipewire.defaultAudioSource;
    if (s?.ready && s?.audio) {
      s.audio.muted = m;
    }
  }

  function setAudioSink(n) {
    Pipewire.preferredDefaultAudioSink = n;
    root._volume = n?.audio?.volume ?? 0;
    root._muted = !!n?.audio?.muted;
  }

  function setAudioSource(n) {
    Pipewire.preferredDefaultAudioSource = n;
    root._inputVolume = n?.audio?.volume ?? 0;
    root._inputMuted = !!n?.audio?.muted;
  }

  function getOutputIcon() {
    if (muted)
      return "volume_off";
    if (volume <= Number.EPSILON)
      return "volume_mute";
    if (volume <= 0.5)
      return "volume_down";
    return "volume_up";
  }

  function getInputIcon() {
    if (inputMuted)
      return "mic_off";
    if (inputVolume <= Number.EPSILON)
      return "mic_off";
    return "mic";
  }
}
