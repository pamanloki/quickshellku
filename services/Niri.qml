pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Window/workspace service with two backends behind ONE API (windowList,
// focusedWindowId, focusedAppId, focusWindow(id), closeWindow(id)):
//   * niri  — its JSON IPC event-stream (workspaces + windows + focus)
//   * wlroots (labwc, etc.) — the wlr-foreign-toplevel protocol via
//     ToplevelManager, so the dock keeps working off niri too.
// The backend is picked at startup from $NIRI_SOCKET. For the wlr backend a
// window "id" is the Toplevel object itself (opaque to callers).
//
// Anti-flicker: the workspaces and windowList arrays feed Repeaters, and
// re-assigning a JS array rebuilds every delegate. niri re-sends full state
// whenever the event stream (re)connects, and emits WindowOpenedOrChanged on
// every title change. So we compute a signature of the *visible* fields and
// only re-assign the array when that signature actually changes — identical or
// title-only updates never touch the Repeaters.
Singleton {
    id: root

    // true when running under niri (JSON IPC available), false → wlr backend.
    readonly property bool onNiri: {
        const s = Quickshell.env("NIRI_SOCKET");
        return !!s && ("" + s).length > 0;
    }

    property var workspaces: []
    property var windowList: []
    property var windows: ({})
    property var focusedWindowId: -1     // int (niri) or Toplevel object (wlr)
    property string focusedTitle: ""
    property string focusedAppId: ""

    property string _wsSig: ""
    property string _wlSig: ""

    // ---- wlr backend (labwc / wlroots) ----
    property var _idMap: new Map()   // Toplevel -> stable numeric id (for the signature)
    property int _idSeq: 0
    property string _wlrSig: ""
    function _idOf(tl) {
        if (!root._idMap.has(tl)) root._idMap.set(tl, ++root._idSeq);
        return root._idMap.get(tl);
    }
    function _wlrRebuild() {
        if (root.onNiri) return;
        const tl = ToplevelManager.toplevels;
        const vals = (tl && tl.values) ? tl.values : [];
        const out = [];
        let sig = "";
        for (let i = 0; i < vals.length; i++) {
            const t = vals[i];
            if (!t) continue;
            out.push({ id: t, app_id: t.appId || "", title: t.title || "" });
            sig += root._idOf(t) + ":" + (t.appId || "") + "|";
        }
        if (sig !== root._wlrSig) { root._wlrSig = sig; root.windowList = out; }
    }

    function _applyWorkspaces(list) {
        let sig = "";
        for (let i = 0; i < list.length; i++) {
            const w = list[i];
            sig += w.id + "," + w.idx + "," + (w.name || "") + "," + (w.is_active === true)
                + "," + (w.is_focused === true) + "," + (w.is_urgent === true)
                + "," + (w.windowCount || 0) + "," + (w.output || "") + "|";
        }
        if (sig === root._wsSig)
            return;
        root._wsSig = sig;
        root.workspaces = list;
    }

    function _applyWindowList(list) {
        let sig = "";
        for (let i = 0; i < list.length; i++)
            sig += list[i].id + ":" + (list[i].app_id || "") + "|";
        if (sig === root._wlSig)
            return;
        root._wlSig = sig;
        root.windowList = list;
    }

    function _rebuildWindowList() {
        const arr = [];
        for (const k in root.windows)
            arr.push(root.windows[k]);
        arr.sort((a, b) => a.id - b.id);
        _applyWindowList(arr);
    }

    function _recountWorkspaces() {
        const counts = ({});
        for (const k in root.windows) {
            const w = root.windows[k];
            counts[w.workspace_id] = (counts[w.workspace_id] || 0) + 1;
        }
        const ws = root.workspaces.slice();
        for (let i = 0; i < ws.length; i++)
            ws[i].windowCount = counts[ws[i].id] || 0;
        _applyWorkspaces(ws);
    }

    function _sortWorkspaces(list) {
        list.sort((a, b) => {
            if (a.output === b.output)
                return a.idx - b.idx;
            return (a.output || "").localeCompare(b.output || "");
        });
        return list;
    }

    function _updateFocusedTitle() {
        const w = root.windows[root.focusedWindowId];
        root.focusedTitle = w ? (w.title || "") : "";
        root.focusedAppId = w ? (w.app_id || "") : "";
    }

    function handleEvent(ev) {
        if (ev.WorkspacesChanged) {
            const list = _sortWorkspaces(ev.WorkspacesChanged.workspaces.slice());
            // carry counts over from current window map
            const counts = ({});
            for (const k in root.windows)
                counts[root.windows[k].workspace_id] = (counts[root.windows[k].workspace_id] || 0) + 1;
            for (let i = 0; i < list.length; i++)
                list[i].windowCount = counts[list[i].id] || 0;
            _applyWorkspaces(list);
        } else if (ev.WorkspaceActivated) {
            const id = ev.WorkspaceActivated.id;
            const ws = root.workspaces.slice();
            let out = null;
            for (let i = 0; i < ws.length; i++)
                if (ws[i].id === id) out = ws[i].output;
            for (let i = 0; i < ws.length; i++) {
                if (ws[i].id === id) {
                    ws[i].is_active = true;
                    ws[i].is_focused = ev.WorkspaceActivated.focused;
                } else {
                    if (ws[i].output === out)
                        ws[i].is_active = false;
                    if (ev.WorkspaceActivated.focused)
                        ws[i].is_focused = false;
                }
            }
            _applyWorkspaces(ws);
        } else if (ev.WorkspaceActiveWindowChanged) {
            // active_window_id isn't rendered; mutate in place, no Repeater churn.
            const ws = root.workspaces;
            for (let i = 0; i < ws.length; i++)
                if (ws[i].id === ev.WorkspaceActiveWindowChanged.workspace_id)
                    ws[i].active_window_id = ev.WorkspaceActiveWindowChanged.active_window_id;
        } else if (ev.WorkspaceUrgencyChanged) {
            const ws = root.workspaces.slice();
            for (let i = 0; i < ws.length; i++)
                if (ws[i].id === ev.WorkspaceUrgencyChanged.id)
                    ws[i].is_urgent = ev.WorkspaceUrgencyChanged.urgent;
            _applyWorkspaces(ws);
        } else if (ev.WindowsChanged) {
            const map = ({});
            const list = ev.WindowsChanged.windows;
            for (let i = 0; i < list.length; i++) {
                map[list[i].id] = list[i];
                if (list[i].is_focused)
                    root.focusedWindowId = list[i].id;
            }
            root.windows = map;
            _rebuildWindowList();
            _recountWorkspaces();
            _updateFocusedTitle();
        } else if (ev.WindowOpenedOrChanged) {
            const w = ev.WindowOpenedOrChanged.window;
            const existed = root.windows[w.id] !== undefined;
            const prevWs = existed ? root.windows[w.id].workspace_id : null;
            root.windows[w.id] = w;
            if (w.is_focused)
                root.focusedWindowId = w.id;
            _updateFocusedTitle();
            // The signature guard makes these no-ops for a title-only change,
            // but we still skip the work when placement clearly didn't move.
            if (!existed || prevWs !== w.workspace_id) {
                _rebuildWindowList();
                _recountWorkspaces();
            }
        } else if (ev.WindowClosed) {
            delete root.windows[ev.WindowClosed.id];
            if (root.focusedWindowId === ev.WindowClosed.id)
                root.focusedWindowId = -1;
            _rebuildWindowList();
            _recountWorkspaces();
            _updateFocusedTitle();
        } else if (ev.WindowFocusChanged) {
            root.focusedWindowId = ev.WindowFocusChanged.id === null ? -1 : ev.WindowFocusChanged.id;
            _updateFocusedTitle();
        } else if (ev.WindowUrgencyChanged) {
            const w = root.windows[ev.WindowUrgencyChanged.id];
            if (w) w.is_urgent = ev.WindowUrgencyChanged.urgent;
        }
    }

    function action(args) {
        actionProc.command = ["niri", "msg", "action"].concat(args);
        actionProc.running = true;
    }

    function focusWorkspace(ws) {
        root.action(["focus-workspace", ws.name ? String(ws.name) : String(ws.idx)]);
    }

    function focusWindow(id) {
        if (!root.onNiri) { if (id && id.activate) id.activate(); return; }
        actionProc.command = ["niri", "msg", "action", "focus-window", "--id", String(id)];
        actionProc.running = true;
    }

    function closeWindow(id) {
        if (!root.onNiri) { if (id && id.close) id.close(); return; }
        actionProc.command = ["niri", "msg", "action", "close-window", "--id", String(id)];
        actionProc.running = true;
    }

    // Minimize / maximize (wlr backend only — labwc etc.). No-op on niri, which
    // has no minimize concept.
    function setMinimized(id, v) {
        if (root.onNiri || !id) return;
        if (typeof id.setMinimized === "function") id.setMinimized(v);
        else if (id.minimized !== undefined) id.minimized = v;
    }
    function toggleMaximize(id) {
        if (root.onNiri || !id) return;
        const cur = id.maximized === true;
        if (typeof id.setMaximized === "function") id.setMaximized(!cur);
        else if (id.maximized !== undefined) id.maximized = !cur;
    }
    function isMinimizable(id) { return !root.onNiri && !!id && id.minimized !== undefined; }

    // ---- wlr backend wiring (inactive under niri) ----
    Binding {
        target: root; property: "focusedWindowId"; when: !root.onNiri
        value: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel : -1
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: root; property: "focusedAppId"; when: !root.onNiri
        value: ToplevelManager.activeToplevel ? (ToplevelManager.activeToplevel.appId || "") : ""
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: root; property: "focusedTitle"; when: !root.onNiri
        value: ToplevelManager.activeToplevel ? (ToplevelManager.activeToplevel.title || "") : ""
        restoreMode: Binding.RestoreNone
    }
    // Rebuild the window list on open/close and per-window app_id changes.
    Instantiator {
        model: root.onNiri ? null : ToplevelManager.toplevels
        delegate: QtObject {
            id: tlWatch
            required property var modelData
            property Connections _c: Connections {
                target: tlWatch.modelData
                function onAppIdChanged() { root._wlrRebuild(); }
            }
            Component.onCompleted: root._wlrRebuild()
            Component.onDestruction: Qt.callLater(root._wlrRebuild)
        }
    }

    Process {
        id: actionProc
        running: false
    }

    // Long-lived event stream. If it drops (see noctalia issue #2200, the niri
    // socket can silently disconnect), we restart it — and because of the
    // signature guards above, the re-sent full state does NOT cause a visible
    // rebuild when nothing actually changed.
    Process {
        id: stream
        command: ["niri", "msg", "--json", "event-stream"]
        running: root.onNiri
        stdout: SplitParser {
            onRead: line => {
                if (!line)
                    return;
                try {
                    root.handleEvent(JSON.parse(line));
                } catch (e) {
                    // ignore malformed / partial lines
                }
            }
        }
        onExited: (code, status) => {
            if (!root.onNiri) return;
            console.log("[Niri] event-stream exited code=" + code + " — restarting");
            restartTimer.start();
        }
    }

    Timer {
        id: restartTimer
        interval: 1000
        onTriggered: if (root.onNiri) stream.running = true
    }
}
