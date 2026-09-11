pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Flavours (Base16/Base24) theme control. Lists schemes as FAMILIES only
// (the dark/light variant is chosen by the light/dark toggle), tracks the
// current one, and applies (reusing flavours-theme for wallpaper + notify).
Singleton {
    id: root

    property var families: []        // unique family base names, sorted
    property var _darkOf: ({})       // family -> dark slug
    property var _lightOf: ({})      // family -> light slug
    property string current: ""      // current full slug

    readonly property string currentMode: _variantMode(current)
    readonly property string currentFamily: _baseName(current)

    function _baseName(s) {
        if (!s) return "";
        s = s.replace("-dark-", "-").replace("-light-", "-");
        s = s.replace(/-dark$/, "").replace(/-light$/, "").replace(/-dawn$/, "").replace(/-day$/, "");
        return s;
    }
    function _variantMode(s) {
        return /(-light$|-light-|-dawn$|-day$)/.test(s || "") ? "light" : "dark";
    }
    function title(fam) {
        return (fam || "").replace(/[-_]/g, " ").replace(/\b\w/g, c => c.toUpperCase());
    }

    function refresh() {
        listProc.running = true;
        curProc.running = true;
    }

    // Apply a family in the current light/dark mode.
    function applyFamily(fam) {
        const mode = _variantMode(root.current);
        let target = mode === "light" ? (root._lightOf[fam] || root._darkOf[fam])
                                       : (root._darkOf[fam] || root._lightOf[fam]);
        if (!target) target = fam;
        _apply(target);
    }

    function toggle() { toggleProc.running = true; }

    function _apply(slug) {
        applyProc.command = ["sh", "-c",
            "flavours apply \"$1\" && FLAVOURS_SCHEME=\"$1\" flavours-theme --post-apply 2>/dev/null || true",
            "sh", slug];
        applyProc.running = true;
    }

    Process {
        id: listProc
        command: ["sh", "-c", "flavours list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const slugs = text.trim().split(/\s+/).filter(x => x.length > 0);
                const dark = ({}), light = ({}), fams = ({});
                for (const s of slugs) {
                    const b = root._baseName(s);
                    fams[b] = true;
                    if (root._variantMode(s) === "light") light[b] = s;
                    else dark[b] = s;
                }
                root._darkOf = dark;
                root._lightOf = light;
                root.families = Object.keys(fams).sort();
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
