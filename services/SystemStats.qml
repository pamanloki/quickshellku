pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// CPU / memory / disk / temperature, polled every 2s with a single process.
// CPU is a delta of /proc/stat; memory from /proc/meminfo; disk via df;
// temperature from the first thermal zone (override zonePath if needed).
Singleton {
    id: root

    property int cpuPercent: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property string diskFree: "--"
    property int tempC: 0

    readonly property string tempClass: tempC >= 80 ? "critical" : (tempC >= 60 ? "warm" : "cool")

    property int _prevIdle: 0
    property int _prevTotal: 0
    property string zonePath: "/sys/class/thermal/thermal_zone0/temp"

    function _parse(out) {
        const sections = out.split("@@@");
        // 0: /proc/stat first line, 1: meminfo, 2: temp, 3: df avail
        if (sections[0]) {
            const p = sections[0].trim().split(/\s+/);
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
        if (sections[1]) {
            const t = sections[1];
            const tot = parseInt((/MemTotal:\s+(\d+)/.exec(t) || [])[1]) || 0;
            const av = parseInt((/MemAvailable:\s+(\d+)/.exec(t) || [])[1]) || 0;
            root.memTotalGiB = tot / 1048576;
            root.memUsedGiB = (tot - av) / 1048576;
        }
        if (sections[2]) {
            const v = parseInt(sections[2].trim());
            if (!isNaN(v))
                root.tempC = Math.round(v / 1000);
        }
        if (sections[3]) {
            const d = sections[3].trim();
            if (d.length > 0)
                root.diskFree = d;
        }
    }

    Process {
        id: proc
        command: ["sh", "-c",
            "head -1 /proc/stat; printf '@@@'; " +
            "grep -E 'MemTotal|MemAvailable' /proc/meminfo; printf '@@@'; " +
            "cat " + root.zonePath + " 2>/dev/null; printf '@@@'; " +
            "df -h --output=avail / | tail -1 | tr -d ' '"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
