pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Screenshot actions (grim + slurp + wl-copy), a native port of the
// screenshot-fuzzel menu: region/full → clipboard/file, saved to
// ~/pictures/ScreenShots, with a notify-send toast (and a failure toast so
// missing tools are obvious). Driven by ScreenshotMenu or niri keybinds:
//   qs ipc call shot region | regionfile | full | fullfile
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/pictures/ScreenShots"

    // last saved screenshot path — a floating thumbnail watches this (macOS-style)
    property string lastShot: ""
    function _stamp() { return Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss"); }
    Process {
        id: shotProc
        property string file: ""
        onExited: (code, status) => {
            if (code === 0 && shotProc.file.length > 0) {
                root.lastShot = "";                       // force change even if same path
                root.lastShot = shotProc.file;
                Quickshell.execDetached(["sh", "-c",
                    'wl-copy -t image/png < "$1" 2>/dev/null; ' +
                    'notify-send -a Screenshot "󰄄 Screenshot tersimpan" "$(basename "$1")"',
                    "sh", shotProc.file]);
            } else if (code !== 0 && code !== 3) {
                Quickshell.execDetached(["sh", "-c", root._fail]);
            }
        }
    }

    // Detached, not a Process: wl-copy daemonises to keep serving the clipboard,
    // and a Process would kill it (and its whole group) when sh exits, wiping
    // the copy. execDetached fully detaches so the capture + clipboard survive.
    function _run(script) {
        Quickshell.execDetached(["sh", "-c", script]);
    }

    // Run one of the actions after a short delay, so a menu that triggered it
    // has time to unmap before grim captures. The timer lives here (in the
    // always-alive singleton) rather than in the popup window, which unmaps
    // immediately on close and would drop its own timer.
    property var _pending: null
    Timer {
        id: delay
        interval: 200
        onTriggered: { if (root._pending) root._pending(); root._pending = null; }
    }
    function menuPick(act) {
        root._pending = act === "rc" ? regionClip
            : act === "rf" ? regionFile
            : act === "fc" ? fullClip
            : fullFile;
        delay.restart();
    }

    readonly property string _fail: 'notify-send -a Screenshot "󰅖 Screenshot gagal" "cek grim / slurp / wl-clipboard"'

    function regionClip() {
        _run('g=$(slurp) || exit 0; t=$(mktemp --suffix=.png); ' +
             'if grim -g "$g" "$t" && wl-copy -t image/png < "$t"; then ' +
             'notify-send -a Screenshot "󰄄 Region disalin" "→ clipboard"; else ' + root._fail + '; fi; rm -f "$t"');
    }
    function regionFile() {
        const f = root.dir + "/shot-" + _stamp() + ".png";
        shotProc.file = f;
        shotProc.command = ["sh", "-c",
            'mkdir -p "$(dirname "$1")"; g=$(slurp) || exit 3; exec grim -g "$g" "$1"', "sh", f];
        shotProc.running = true;
    }
    function fullClip() {
        _run('t=$(mktemp --suffix=.png); ' +
             'if grim "$t" && wl-copy -t image/png < "$t"; then ' +
             'notify-send -a Screenshot "󰄄 Layar penuh disalin" "→ clipboard"; else ' + root._fail + '; fi; rm -f "$t"');
    }
    function fullFile() {
        const f = root.dir + "/shot-" + _stamp() + ".png";
        shotProc.file = f;
        shotProc.command = ["sh", "-c",
            'mkdir -p "$(dirname "$1")"; exec grim "$1"', "sh", f];
        shotProc.running = true;
    }

    IpcHandler {
        target: "shot"
        function region() { root.regionClip(); }
        function regionfile() { root.regionFile(); }
        function full() { root.fullClip(); }
        function fullfile() { root.fullFile(); }
    }
}
