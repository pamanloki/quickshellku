pragma Singleton

import Quickshell
import Quickshell.Io

// Screenshot actions (grim + slurp + wl-copy), a native port of the
// screenshot-fuzzel menu: region/full → clipboard/file, saved to
// ~/pictures/ScreenShots, with a notify-send toast. Driven by ScreenshotMenu or
// directly by niri keybinds:
//   qs ipc call shot region | regionfile | full | fullfile
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/pictures/ScreenShots"

    function _run(script) {
        proc.command = ["sh", "-c", script];
        proc.running = true;
    }

    // shared shell prelude: make the dir and pick a timestamped filename
    readonly property string _prep: 'd="$HOME/pictures/ScreenShots"; mkdir -p "$d"; f="$d/shot-$(date +%F_%H-%M-%S).png"; '
    readonly property string _saved: ' && { wl-copy -t image/png < "$f" 2>/dev/null || true; notify-send -a Screenshot "󰄄 Screenshot tersimpan" "$(basename "$f")"; }'

    function regionClip() {
        _run('g=$(slurp) || exit 0; [ -z "$g" ] && exit 0; ' +
             'grim -g "$g" - | wl-copy -t image/png && notify-send -a Screenshot "󰄄 Region disalin" "→ clipboard"');
    }
    function regionFile() {
        _run(root._prep + 'g=$(slurp) || exit 0; [ -z "$g" ] && exit 0; grim -g "$g" "$f"' + root._saved);
    }
    function fullClip() {
        _run('grim - | wl-copy -t image/png && notify-send -a Screenshot "󰄄 Layar penuh disalin" "→ clipboard"');
    }
    function fullFile() {
        _run(root._prep + 'grim "$f"' + root._saved);
    }

    Process { id: proc }

    IpcHandler {
        target: "shot"
        function region() { root.regionClip(); }
        function regionfile() { root.regionFile(); }
        function full() { root.fullClip(); }
        function fullfile() { root.fullFile(); }
    }
}
