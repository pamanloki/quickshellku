pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// XBPS update checker (Void Linux). Counts pending updates with
// `xbps-install -Mun` (memory-sync + dry-run → fresh list, no root), every
// 30 min. The bar pill hides itself when there's nothing to update; clicking it
// opens a terminal to actually upgrade.
Singleton {
    id: root

    property int count: 0
    property bool checking: false

    function refresh() {
        root.checking = true;
        proc.running = true;
    }

    function runUpdate() {
        Quickshell.execDetached(["footx", "-e", "-f", "sh", "-c",
            "sudo xbps-install -Su; printf '\\n[selesai] tekan Enter untuk menutup...'; read _"]);
        // re-check a little after the terminal likely closed
        recheck.restart();
    }

    Process {
        id: proc
        command: ["sh", "-c", "xbps-install -Mun 2>/dev/null | grep -c . || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.count = parseInt(text.trim()) || 0;
                root.checking = false;
            }
        }
    }

    // Gentle re-check after an update run (30s), plus the periodic poll.
    Timer { id: recheck; interval: 30000; onTriggered: root.refresh() }
    Timer {
        interval: 1800000   // 30 min
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
