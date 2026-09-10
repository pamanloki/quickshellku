pragma Singleton

import Quickshell
import QtQuick

// Single shared clock tick (mirrors noctalia's Commons/Time).
// A plain Timer + Date is more predictable than SystemClock across Quickshell
// versions. `now` updates once a second, re-synced to the second boundary.
Singleton {
    id: root

    property var now: new Date()
    property real _lastTs: Date.now()

    Timer {
        id: tick
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: false
        onTriggered: {
            const d = new Date();
            root.now = d;
            // keep aligned to the start of each second
            const ms = d.getMilliseconds();
            if (ms > 100) {
                tick.interval = 1000 - ms + 10;
                tick.restart();
            } else {
                tick.interval = 1000;
            }
        }
    }

    Component.onCompleted: {
        const ms = (new Date()).getMilliseconds();
        tick.interval = 1000 - ms + 10;
        tick.restart();
    }
}
