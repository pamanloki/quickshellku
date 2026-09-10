pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// XBPS update count (Void). `xbps-install -Mun` does a dry-run against the
// local repo cache (no root needed) and lists one package per line; we count
// those. Checked hourly, matching your Waybar custom/xbps interval.
Singleton {
    id: root

    property int count: 0
    property string state: "up-to-date" // up-to-date / updates / offline

    property string _out: ""

    function refresh() {
        proc.running = true;
    }

    Process {
        id: proc
        command: ["xbps-install", "-Mun"]
        stdout: StdioCollector {
            onStreamFinished: root._out = text
        }
        onExited: (code, status) => {
            if (code !== 0) {
                root.state = "offline";
                root.count = 0;
                return;
            }
            const lines = root._out.split("\n").filter(l => l.trim().length > 0);
            root.count = lines.length;
            root.state = lines.length > 0 ? "updates" : "up-to-date";
        }
    }

    Timer {
        interval: 3600000 // 1 hour
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
