pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Audio control for niri keybinds (WirePlumber/Pipewire), mirroring vols.sh:
//   qs ipc call audio up | down | toggle | togglemic | get
// Uses the native Pipewire service so the volume OSD reacts automatically.
Singleton {
    id: root

    property int step: 5

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    function _setSink(v) {
        if (!sink || !sink.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v)); // clamp to 100%
    }
    function volUp()   { if (sink && sink.audio) _setSink(sink.audio.volume + step / 100); }
    function volDown() { if (sink && sink.audio) _setSink(sink.audio.volume - step / 100); }
    function muteToggle() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted; }
    function micToggle()  { if (source && source.audio) source.audio.muted = !source.audio.muted; }

    IpcHandler {
        target: "audio"
        function up() { root.volUp(); }
        function down() { root.volDown(); }
        function toggle() { root.muteToggle(); }
        function togglemic() { root.micToggle(); }
        function get(): string { return String(root.volume); }
    }
}
