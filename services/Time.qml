pragma Singleton

import Quickshell
import QtQuick

// Single shared clock tick (mirrors noctalia's Commons/Time).
// A plain Timer + Date is more predictable than SystemClock across Quickshell
// versions. The only consumers (menu-bar "HH:mm" clock, calendar's day) need
// minute granularity, so we tick once a minute — aligned to the minute
// boundary so the clock flips exactly on the change — instead of once a second.
// That is 60x fewer QML wakeups, keeping the event loop idle (better for
// battery / heat). Switch to a per-second re-align only if a seconds clock is
// ever added.
Singleton {
    id: root

    property var now: new Date()

    function _msToNextMinute(d) {
        return 60000 - (d.getSeconds() * 1000 + d.getMilliseconds());
    }

    Timer {
        id: tick
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: false
        onTriggered: {
            const d = new Date();
            root.now = d;
            // keep aligned to the start of each minute
            const ms = root._msToNextMinute(d);
            tick.interval = ms > 500 ? ms : 60000;
            tick.restart();
        }
    }

    Component.onCompleted: {
        tick.interval = root._msToNextMinute(new Date()) + 10;
        tick.restart();
    }
}
