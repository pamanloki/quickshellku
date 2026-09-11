pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Persisted dock configuration: the list of pinned app ids ("Keep in Dock").
// Stored as JSON so it survives restarts.
Singleton {
    id: root

    property var pinned: ["brave", "foot"]

    readonly property string path:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
        + "/quickshellku/dock_pinned.json"

    function _norm(s) { return (s || "").toLowerCase().replace(/[^a-z0-9]/g, ""); }
    function isPinned(appId) {
        const n = _norm(appId);
        return root.pinned.some(p => _norm(p) === n);
    }
    function pin(appId) {
        if (!appId || isPinned(appId)) return;
        const a = root.pinned.slice();
        a.push(appId);
        root.pinned = a;
        _save();
    }
    function unpin(appId) {
        const n = _norm(appId);
        root.pinned = root.pinned.filter(p => _norm(p) !== n);
        _save();
    }
    // move a pinned app to a new index (drag reorder)
    function moveTo(appId, idx) {
        const n = _norm(appId);
        const a = root.pinned.slice();
        const i = a.findIndex(p => _norm(p) === n);
        if (i < 0) return;
        idx = Math.max(0, Math.min(a.length - 1, idx));
        if (idx === i) return;
        const it = a.splice(i, 1)[0];
        a.splice(idx, 0, it);
        root.pinned = a;
        _save();
    }

    FileView {
        id: file
        path: root.path
        printErrors: false
        onLoaded: {
            try {
                const a = JSON.parse(text() || "[]");
                if (Array.isArray(a) && a.length > 0) root.pinned = a;
            } catch (e) {}
        }
    }
    Component.onCompleted: file.reload()

    Process { id: saveProc }
    function _save() {
        saveProc.command = ["sh", "-c",
            "mkdir -p \"$(dirname \"$1\")\"; printf %s \"$2\" > \"$1\"",
            "sh", root.path, JSON.stringify(root.pinned)];
        saveProc.running = true;
    }
}
