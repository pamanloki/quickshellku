pragma Singleton

import Quickshell
import Quickshell.Io

// Flavours (Base16/Base24) theme control. Lists schemes, tracks the current
// one, applies a scheme (reusing your flavours-theme wrapper for wallpaper +
// notification), and toggles light/dark.
Singleton {
    id: root

    property var schemes: []     // list of scheme slugs
    property string current: ""

    function refresh() {
        listProc.running = true;
        curProc.running = true;
    }

    function apply(slug) {
        // apply the scheme, then run the wrapper's post-apply so the wallpaper
        // and notification follow (same behaviour as the fuzzel picker).
        applyProc.command = ["sh", "-c",
            "flavours apply \"$1\" && FLAVOURS_SCHEME=\"$1\" flavours-theme --post-apply 2>/dev/null || true",
            "sh", slug];
        applyProc.running = true;
    }

    function toggle() {
        toggleProc.running = true;
    }

    Process {
        id: listProc
        command: ["sh", "-c", "flavours list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.schemes = text.trim().split(/\s+/).filter(x => x.length > 0).sort();
            }
        }
    }
    Process {
        id: curProc
        command: ["sh", "-c", "flavours current 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root.current = text.trim()
        }
    }
    Process { id: applyProc; onExited: root.refresh() }
    Process { id: toggleProc; command: ["flavours-theme", "--toggle"]; onExited: root.refresh() }

    Component.onCompleted: refresh()
}
