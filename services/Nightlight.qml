pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Night light (wlsunset) state + actions. Actions are delegated to your
// existing `nightlight-fuzzel` script via its non-interactive flags, so the
// wlsunset spawn/detach/schedule logic stays identical; this only drives it
// from a native panel and reads back the state.
//   * active   : is wlsunset running (pgrep)
//   * nightTemp/dayTemp : read from the script's state config file
Singleton {
    id: root

    property bool active: false
    property int nightTemp: 3700
    property int dayTemp: 6500
    readonly property int minTemp: 2500
    readonly property int maxTemp: 6500
    readonly property int step: 200

    property string statePath: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/nightlight/config"

    function refresh() {
        runningProc.running = true;
        confFile.reload();
    }

    function _run(flag, extra) {
        const cmd = ["nightlight-fuzzel", flag];
        if (extra !== undefined)
            cmd.push(String(extra));
        actProc.command = cmd;
        actProc.running = true;
    }

    function enable() { _run("--on"); }
    function disable() { _run("--off"); }
    function toggle() { _run("--toggle"); }
    function warmer() { _run("--warmer"); }
    function cooler() { _run("--cooler"); }
    function setTemp(k) { _run("--set", Math.round(k)); }
    function scheduleAuto() { _run("--auto"); }
    function scheduleManual() { _run("--manual"); }

    Process {
        id: actProc
        onExited: settle.restart()
    }
    // brief delay so pgrep / the config file reflect the change
    Timer {
        id: settle
        interval: 400
        onTriggered: root.refresh()
    }

    Process {
        id: runningProc
        command: ["sh", "-c", "pgrep -x wlsunset >/dev/null && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: root.active = text.trim() === "on"
        }
    }

    FileView {
        id: confFile
        path: root.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const t = text();
            const d = /DAY_TEMP=(\d+)/.exec(t);
            const n = /NIGHT_TEMP=(\d+)/.exec(t);
            if (d) root.dayTemp = parseInt(d[1]);
            if (n) root.nightTemp = parseInt(n[1]);
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
