pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// CPU / memory / disk / temperature, polled every 2s with a single process.
//
// Memory matches your Waybar memory_usage.sh (htop-style):
//   used = MemTotal - (MemFree + Active(file) + Inactive(file) + SReclaimable)
// Temperature matches your temp.sh: `sensors` "Package id 0", thresholds
// warm >= 55, critical >= 70.
Singleton {
    id: root

    property int cpuPercent: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property string memText: "--"
    property string diskFree: "--"
    property int tempC: 0
    property bool tempKnown: false

    property string diskUsed: "--"
    property string diskTotal: "--"
    property int diskPercent: 0
    readonly property real memPercent: memTotalGiB > 0 ? Math.round(memUsedGiB / memTotalGiB * 100) : 0

    readonly property string tempClass: !tempKnown ? "unknown"
        : (tempC >= 70 ? "critical" : (tempC >= 55 ? "warm" : "cool"))

    property int _prevIdle: 0
    property int _prevTotal: 0

    function _num(re, txt) {
        const m = re.exec(txt);
        return m ? (parseInt(m[1]) || 0) : 0;
    }

    function _parse(out) {
        const s = out.split("@@@");

        // 0: /proc/stat first line
        if (s[0]) {
            const p = s[0].trim().split(/\s+/);
            if (p[0] === "cpu") {
                let total = 0;
                for (let i = 1; i < p.length; i++)
                    total += parseInt(p[i]) || 0;
                const idle = (parseInt(p[4]) || 0) + (parseInt(p[5]) || 0);
                const dTotal = total - root._prevTotal;
                const dIdle = idle - root._prevIdle;
                if (dTotal > 0)
                    root.cpuPercent = Math.round(100 * (dTotal - dIdle) / dTotal);
                root._prevTotal = total;
                root._prevIdle = idle;
            }
        }

        // 1: /proc/meminfo (kB), htop-style used
        if (s[1]) {
            const t = s[1];
            const total = _num(/MemTotal:\s+(\d+)/, t);
            const free = _num(/MemFree:\s+(\d+)/, t);
            const af = _num(/Active\(file\):\s+(\d+)/, t);
            const iaf = _num(/Inactive\(file\):\s+(\d+)/, t);
            const sr = _num(/SReclaimable:\s+(\d+)/, t);
            const used = total - (free + af + iaf + sr); // kB
            root.memTotalGiB = total / 1048576;
            root.memUsedGiB = used / 1048576;
            root.memText = used < 1048576
                ? Math.round(used / 1024) + "MiB"
                : (used / 1048576).toFixed(1) + "GiB";
        }

        // 2: `sensors` Package id 0 line, e.g. "Package id 0:  +45.0°C  (...)"
        if (s[2] && s[2].trim().length > 0) {
            const m = /([+-]?\d+(?:\.\d+)?)\s*°?C/.exec(s[2]);
            if (m) {
                root.tempC = Math.round(parseFloat(m[1]));
                root.tempKnown = true;
            }
        } else {
            root.tempKnown = false;
        }

        // 3: df on / → "avail used size pcent" (e.g. "40G 55G 100G 58%")
        if (s[3] && s[3].trim().length > 0) {
            const parts = s[3].trim().split(/\s+/);
            root.diskFree = parts[0] || "--";
            root.diskUsed = parts[1] || "--";
            root.diskTotal = parts[2] || "--";
            root.diskPercent = parts[3] ? (parseInt(parts[3]) || 0) : 0;
        }
    }

    // Disk usage barely moves, so we only append the (comparatively expensive)
    // `df` every 10th tick; on the other ticks _parse keeps the previous value.
    property int _tick: 0

    Process {
        id: proc
        command: ["sh", "-c",
            "head -1 /proc/stat; printf '@@@'; " +
            "cat /proc/meminfo; printf '@@@'; " +
            "sensors 2>/dev/null | grep -m1 'Package id 0'; printf '@@@'; " +
            ((root._tick % 10 === 0)
                ? "df -h --output=avail,used,size,pcent / | tail -1" : "")]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    // 3s keeps CPU%/temp/mem lively in the bar without hammering the CPU the way
    // a 2s `sensors` spawn did (~33% fewer wakeups, and far fewer `df` calls).
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { root._tick++; proc.running = true; }
    }
}
