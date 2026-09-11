pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// (IpcHandler declared at the bottom for niri keybinds)

// Backlight control via `light` (your setup).
//   light -G      -> current brightness as a percent (float)
//   light -S N    -> set to N percent
//   light -A N    -> raise by N percent
//   light -U N    -> lower by N percent
Singleton {
    id: root

    property int percent: 0
    property int step: 5

    // Clean sun glyph (level is shown by the value/percent).
    readonly property string icon: "󰖨"

    function refresh() {
        getProc.running = true;
    }

    function set(p) {
        p = Math.max(1, Math.min(100, Math.round(p)));
        _run(["light", "-S", String(p)]);
    }

    function raise() {
        _run(["light", "-A", String(step)]);
    }

    function lower() {
        _run(["light", "-U", String(step)]);
    }

    function _run(cmd) {
        setProc.command = cmd;
        setProc.running = true;
    }

    Process {
        id: setProc
        onExited: root.refresh()
    }

    Process {
        id: getProc
        command: ["light", "-G"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(text.trim());
                if (!isNaN(v))
                    root.percent = Math.round(v);
            }
        }
    }

    // Light poll so external changes (e.g. keyboard keys via light) stay in sync.
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    // Keybinds: qs ipc call brightness up|down (the OSD reacts to percent).
    IpcHandler {
        target: "brightness"
        function up() { root.raise(); }
        function down() { root.lower(); }
        function refresh() { root.refresh(); }
    }
}
