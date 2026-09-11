pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Talks to niri over its JSON IPC.
//   * an event-stream Process keeps workspaces / windows / focus live
//   * action() fires one-shot `niri msg action ...` commands
//
// Anti-flicker: the workspaces and windowList arrays feed Repeaters, and
// re-assigning a JS array rebuilds every delegate. niri re-sends full state
// whenever the event stream (re)connects, and emits WindowOpenedOrChanged on
// every title change. So we compute a signature of the *visible* fields and
// only re-assign the array when that signature actually changes — identical or
// title-only updates never touch the Repeaters.
Singleton {
    id: root

    property var workspaces: []
    property var windowList: []
    property var windows: ({})
    property int focusedWindowId: -1
    property string focusedTitle: ""
    property string focusedAppId: ""

    property string _wsSig: ""
    property string _wlSig: ""

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
        actionProc.command = ["niri", "msg", "action", "focus-window", "--id", String(id)];
        actionProc.running = true;
    }

    function closeWindow(id) {
        actionProc.command = ["niri", "msg", "action", "close-window", "--id", String(id)];
        actionProc.running = true;
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
        running: true
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
            console.log("[Niri] event-stream exited code=" + code + " — restarting");
            restartTimer.start();
        }
    }

    Timer {
        id: restartTimer
        interval: 1000
        onTriggered: stream.running = true
    }
}
