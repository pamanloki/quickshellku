pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Battery state from /sys/class/power_supply, polled every 5s with one process.
// On desktops (no Battery-type supply) `present` stays false and the menu bar
// indicator hides itself.
Singleton {
    id: root

    property bool present: false
    property int percent: 0
    property string status: ""       // Charging | Discharging | Full | Not charging
    readonly property bool charging: status === "Charging" || status === "Full"
    readonly property bool low: present && !charging && percent <= 20
    readonly property bool critical: present && !charging && percent <= 10

    // Nerd Font (md) battery glyph by level + charge state.
    readonly property string icon: {
        if (!present) return "󰂑";
        if (charging) return "󰂄";
        if (percent >= 95) return "󰁹";
        if (percent >= 85) return "󰂂";
        if (percent >= 75) return "󰂁";
        if (percent >= 65) return "󰂀";
        if (percent >= 55) return "󰁿";
        if (percent >= 45) return "󰁾";
        if (percent >= 35) return "󰁽";
        if (percent >= 25) return "󰁼";
        if (percent >= 15) return "󰁻";
        if (percent >= 5)  return "󰁺";
        return "󰂃";
    }

    function _parse(out) {
        const t = out.trim();
        if (t.length === 0) { root.present = false; return; }
        const s = t.split("@@@");
        const cap = parseInt(s[0]);
        if (isNaN(cap)) { root.present = false; return; }
        root.present = true;
        root.percent = Math.max(0, Math.min(100, cap));
        root.status = (s[1] || "").trim();
    }

    Process {
        id: proc
        command: ["sh", "-c",
            "for d in /sys/class/power_supply/*; do " +
            "  [ \"$(cat \"$d/type\" 2>/dev/null)\" = Battery ] || continue; " +
            "  printf '%s@@@%s' \"$(cat \"$d/capacity\" 2>/dev/null)\" \"$(cat \"$d/status\" 2>/dev/null)\"; " +
            "  break; " +
            "done"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
