pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Lightweight system info for the "About This System" panel — os-release,
// kernel, hostname, CPU model and uptime. Memory comes from SystemStats.
Singleton {
    id: root

    property string osPretty: "Linux"
    property string kernel: ""
    property string hostname: ""
    property string cpu: ""
    property string uptime: ""
    readonly property string user: Quickshell.env("USER")
    readonly property string desktop: Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "niri"
    readonly property string shell: (Quickshell.env("SHELL") || "").split("/").pop()

    function _fmtUptime(sec) {
        sec = Math.floor(sec);
        const d = Math.floor(sec / 86400);
        const h = Math.floor((sec % 86400) / 3600);
        const m = Math.floor((sec % 3600) / 60);
        const parts = [];
        if (d > 0) parts.push(d + "d");
        if (h > 0) parts.push(h + "h");
        parts.push(m + "m");
        return parts.join(" ");
    }

    function refresh() { proc.running = true; }

    Process {
        id: proc
        command: ["sh", "-c",
            ". /etc/os-release 2>/dev/null; printf '%s@@@' \"$PRETTY_NAME\"; " +
            "printf '%s@@@' \"$(uname -r)\"; " +
            "printf '%s@@@' \"$(uname -n)\"; " +
            "printf '%s@@@' \"$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//')\"; " +
            "cut -d' ' -f1 /proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.split("@@@");
                if (s[0] && s[0].trim().length) root.osPretty = s[0].trim();
                if (s[1]) root.kernel = s[1].trim();
                if (s[2]) root.hostname = s[2].trim();
                if (s[3] && s[3].trim().length) root.cpu = s[3].trim();
                if (s[4]) root.uptime = root._fmtUptime(parseFloat(s[4]) || 0);
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
