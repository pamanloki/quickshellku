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
    property real timeHours: 0       // est. hours to empty (discharging) / to full (charging); 0 = unknown
    readonly property bool charging: status === "Charging" || status === "Full"
    readonly property bool low: present && !charging && percent <= 20
    readonly property bool critical: present && !charging && percent <= 10

    // Fires once when the battery drops past 20% and again past 10% while
    // discharging. Resets after charging or rising back above the threshold.
    signal lowWarning(int level)
    property int _warnedAt: 0   // 0 | 20 | 10

    readonly property string powerSource: charging ? "Power Adapter" : "Battery"
    readonly property string statusText: {
        if (!present) return "No Battery";
        if (status === "Full" || percent >= 100) return "Fully Charged";
        return charging ? "Charging" : "On Battery";
    }
    // "1:25 remaining" / "0:40 to full" / "" when unknown.
    readonly property string timeText: {
        if (!present || timeHours <= 0 || status === "Full" || percent >= 100) return "";
        const h = Math.floor(timeHours);
        const m = Math.round((timeHours - h) * 60);
        const hh = m === 60 ? h + 1 : h;
        const mm = m === 60 ? 0 : m;
        const t = hh + ":" + (mm < 10 ? "0" + mm : mm);
        return charging ? (t + " to full") : (t + " remaining");
    }

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

    function _n(v) { const x = parseFloat(v); return isNaN(x) ? 0 : x; }

    function _parse(out) {
        const t = out.trim();
        if (t.length === 0) { root.present = false; return; }
        const s = t.split("@@@");
        const cap = parseInt(s[0]);
        if (isNaN(cap)) { root.present = false; return; }
        root.present = true;
        root.percent = Math.max(0, Math.min(100, cap));
        root.status = (s[1] || "").trim();

        // Time estimate from energy_* (µWh/µW) or charge_*/current_* (µAh/µA).
        const eNow = _n(s[2]), eFull = _n(s[3]), pNow = _n(s[4]);
        const cNow = _n(s[5]), cFull = _n(s[6]), iNow = _n(s[7]);
        let hrs = 0;
        if (pNow > 0 && eFull > 0) {
            hrs = root.charging ? (eFull - eNow) / pNow : eNow / pNow;
        } else if (iNow > 0 && cFull > 0) {
            hrs = root.charging ? (cFull - cNow) / iNow : cNow / iNow;
        }
        root.timeHours = (hrs > 0 && hrs < 48) ? hrs : 0;

        // low-battery warning with hysteresis
        if (root.charging || root.percent > 22) {
            root._warnedAt = 0;
        } else {
            if (root.percent <= 10 && root._warnedAt !== 10) {
                root._warnedAt = 10;
                root.lowWarning(10);
            } else if (root.percent <= 20 && root._warnedAt === 0) {
                root._warnedAt = 20;
                root.lowWarning(20);
            }
        }
    }

    Process {
        id: proc
        command: ["sh", "-c",
            "for d in /sys/class/power_supply/*; do " +
            "  [ \"$(cat \"$d/type\" 2>/dev/null)\" = Battery ] || continue; " +
            "  printf '%s@@@%s@@@%s@@@%s@@@%s@@@%s@@@%s@@@%s' " +
            "    \"$(cat \"$d/capacity\" 2>/dev/null)\" " +
            "    \"$(cat \"$d/status\" 2>/dev/null)\" " +
            "    \"$(cat \"$d/energy_now\" 2>/dev/null)\" " +
            "    \"$(cat \"$d/energy_full\" 2>/dev/null)\" " +
            "    \"$(cat \"$d/power_now\" 2>/dev/null)\" " +
            "    \"$(cat \"$d/charge_now\" 2>/dev/null)\" " +
            "    \"$(cat \"$d/charge_full\" 2>/dev/null)\" " +
            "    \"$(cat \"$d/current_now\" 2>/dev/null)\"; " +
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
