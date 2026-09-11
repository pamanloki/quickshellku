pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Battery status from /sys/class/power_supply, polled every 10s (cheap — just
// reads two sysfs files, no heavy tooling). Exposes raw data only; the bar
// module maps it to theme colours. `present` is false on desktops so the pill
// hides itself.
Singleton {
    id: root

    property bool present: false
    property int percent: 0
    property string status: "Unknown"   // Charging / Discharging / Full / ...

    readonly property bool charging: status === "Charging" || status === "Full"
    readonly property bool low: present && !charging && percent <= 20
    readonly property bool critical: present && !charging && percent <= 10

    // Nerd Font battery glyphs (charging, then 10%..100% buckets).
    readonly property string icon: {
        if (!present) return "";
        if (charging) return "󰂄";
        const g = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        return g[Math.min(9, Math.max(0, Math.floor((percent - 1) / 10)))];
    }

    function refresh() { proc.running = true; }

    Process {
        id: proc
        command: ["sh", "-c",
            "for b in /sys/class/power_supply/BAT*; do [ -d \"$b\" ] || continue; " +
            "printf '%s %s' \"$(cat \"$b/capacity\" 2>/dev/null)\" \"$(cat \"$b/status\" 2>/dev/null)\"; break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (!t) { root.present = false; return; }
                const p = t.split(/\s+/);
                const cap = parseInt(p[0]);
                if (isNaN(cap)) { root.present = false; return; }
                root.present = true;
                root.percent = Math.max(0, Math.min(100, cap));
                root.status = p[1] || "Unknown";
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
