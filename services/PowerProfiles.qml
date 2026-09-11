pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Power profiles via `powerprofilesctl` (power-profiles-daemon). If the tool
// isn't installed, `available` stays false and the Quick Settings tile hides
// itself. Cheap: two reads on a 15s poll, plus an immediate re-read after a set.
Singleton {
    id: root

    property bool available: false
    property string current: ""        // power-saver | balanced | performance
    property var profiles: []          // available profiles, in daemon order

    readonly property string icon: current === "performance" ? "󰓅"
        : current === "power-saver" ? "󰌪"
        : "󰾅"
    readonly property string label: current === "power-saver" ? "Saver"
        : current === "performance" ? "Performance"
        : current === "balanced" ? "Balanced"
        : "Power"

    function refresh() {
        getProc.running = true;
        listProc.running = true;
    }
    function set(p) {
        if (!p) return;
        setProc.command = ["powerprofilesctl", "set", p];
        setProc.running = true;
    }
    function cycle() {
        if (profiles.length === 0) return;
        const i = profiles.indexOf(current);
        set(profiles[(i + 1) % profiles.length]);
    }

    Process {
        id: getProc
        command: ["sh", "-c", "powerprofilesctl get 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t) { root.available = true; root.current = t; }
            }
        }
    }
    Process {
        id: listProc
        command: ["sh", "-c",
            "powerprofilesctl list 2>/dev/null | grep -oE '(power-saver|balanced|performance)' | awk '!seen[$0]++'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const arr = text.trim().split(/\s+/).filter(x => x.length > 0);
                if (arr.length) root.profiles = arr;
            }
        }
    }
    Process { id: setProc; onExited: root.refresh() }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
