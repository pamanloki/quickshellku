import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "root:/services"

// wireplumber equivalent using Quickshell's native Pipewire service.
// Scroll to change volume; left click opens pavucontrol; right click mutes.
Item {
    id: root
    implicitWidth: pill.implicitWidth
    implicitHeight: Theme.barHeight

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0

    // Keep the default sink's audio object bound and live.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    function icon() {
        if (muted || volume === 0)
            return "󰖁";
        return "󰋋";
    }

    function setVolume(v) {
        if (!sink || !sink.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    StatPill {
        id: pill
        icon: root.icon()
        value: root.muted ? "Mute" : (root.volume + "%")
        valueMax: "100%"
        accent: Theme.base0D
        onClicked: Quickshell.execDetached(["pavucontrol"])
        onScrollUp: root.setVolume((root.volume + 5) / 100)
        onScrollDown: root.setVolume((root.volume - 5) / 100)
        onRightClicked: {
            if (root.sink && root.sink.audio)
                root.sink.audio.muted = !root.sink.audio.muted;
        }
    }
}
