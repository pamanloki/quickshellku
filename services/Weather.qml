pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Weather from wttr.in (auto-locates by IP). Polled every 30 min. Falls back
// to hidden (ok=false) when offline or the request fails.
Singleton {
    id: root

    property string temp: ""      // e.g. "28°C"
    property string cond: ""      // condition text
    property string place: ""     // location name
    property bool ok: false

    // Nerd Font (md) weather glyph from the condition text.
    readonly property string icon: {
        if (!ok) return "󰖐";
        const c = cond.toLowerCase();
        if (c.indexOf("thunder") >= 0) return "󰖓";
        if (c.indexOf("snow") >= 0 || c.indexOf("sleet") >= 0 || c.indexOf("blizzard") >= 0 || c.indexOf("ice") >= 0) return "󰖘";
        if (c.indexOf("rain") >= 0 || c.indexOf("drizzle") >= 0 || c.indexOf("shower") >= 0) return "󰖗";
        if (c.indexOf("fog") >= 0 || c.indexOf("mist") >= 0 || c.indexOf("haze") >= 0) return "󰖑";
        if (c.indexOf("overcast") >= 0) return "󰖐";
        if (c.indexOf("partly") >= 0) return "󰖕";
        if (c.indexOf("cloud") >= 0) return "󰖐";
        if (c.indexOf("clear") >= 0 || c.indexOf("sunny") >= 0) return "󰖙";
        return "󰖐";
    }

    function _parse(out) {
        const t = (out || "").trim();
        // format: "+28°C|Partly cloudy|Jakarta"
        if (t.length === 0 || t.toLowerCase().indexOf("unknown location") >= 0
            || t.indexOf("|") < 0) { root.ok = false; return; }
        const p = t.split("|");
        const tt = (p[0] || "").replace("+", "").trim();
        if (tt.length === 0 || tt.indexOf("°") < 0) { root.ok = false; return; }
        root.temp = tt;
        root.cond = (p[1] || "").trim();
        root.place = (p[2] || "").trim();
        root.ok = true;
    }

    function refresh() { proc.running = true; }

    Process {
        id: proc
        command: ["sh", "-c", "curl -s --max-time 12 'wttr.in/?format=%t|%C|%l' 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root._parse(text) }
    }

    Timer {
        interval: 1800000   // 30 min
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    IpcHandler {
        target: "weather"
        function refresh() { root.refresh(); }
    }
}
