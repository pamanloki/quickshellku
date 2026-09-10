pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Talks to niri over its JSON IPC.
//   * an event-stream Process keeps workspaces / windows / focus live
//   * action() fires one-shot `niri msg action ...` commands
//
// niri emits a full WorkspacesChanged and WindowsChanged right after the
// stream opens, so we get initial state for free.
Singleton {
    id: root

    // Sorted list of workspace objects: {id, idx, name, output, is_active,
    // is_focused, is_urgent, active_window_id, windowCount}
    property var workspaces: []
    // Map of window id -> window object {id, title, app_id, workspace_id, ...}
    property var windows: ({})
    property int focusedWindowId: -1
    property string focusedTitle: ""
    property string focusedAppId: ""

    // Windows in a stable order for the taskbar (by id).
    property var windowList: []

    function _rebuildWindowList() {
        const arr = [];
        for (const k in root.windows)
            arr.push(root.windows[k]);
        arr.sort((a, b) => a.id - b.id);
        root.windowList = arr;
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
        root.workspaces = ws;
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
            const list = ev.WorkspacesChanged.workspaces.slice();
            root.workspaces = _sortWorkspaces(list);
            _recountWorkspaces();
        } else if (ev.WorkspaceActivated) {
            const id = ev.WorkspaceActivated.id;
            const ws = root.workspaces.slice();
            for (let i = 0; i < ws.length; i++) {
                // Only one workspace per output is active; niri sends the newly
                // activated one. Mark focus on the matching output.
                if (ws[i].id === id) {
                    ws[i].is_active = true;
                    ws[i].is_focused = ev.WorkspaceActivated.focused;
                } else if (ev.WorkspaceActivated.focused) {
                    ws[i].is_focused = false;
                }
            }
            // Clear is_active for others on the same output as the activated one.
            let out = null;
            for (let i = 0; i < ws.length; i++)
                if (ws[i].id === id) out = ws[i].output;
            for (let i = 0; i < ws.length; i++)
                if (ws[i].output === out && ws[i].id !== id)
                    ws[i].is_active = false;
            root.workspaces = ws;
        } else if (ev.WorkspaceActiveWindowChanged) {
            const ws = root.workspaces.slice();
            for (let i = 0; i < ws.length; i++)
                if (ws[i].id === ev.WorkspaceActiveWindowChanged.workspace_id)
                    ws[i].active_window_id = ev.WorkspaceActiveWindowChanged.active_window_id;
            root.workspaces = ws;
        } else if (ev.WorkspaceUrgencyChanged) {
            const ws = root.workspaces.slice();
            for (let i = 0; i < ws.length; i++)
                if (ws[i].id === ev.WorkspaceUrgencyChanged.id)
                    ws[i].is_urgent = ev.WorkspaceUrgencyChanged.urgent;
            root.workspaces = ws;
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
            root.windows[w.id] = w;
            if (w.is_focused)
                root.focusedWindowId = w.id;
            _rebuildWindowList();
            _recountWorkspaces();
            _updateFocusedTitle();
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

    // Fire a niri action, e.g. action(["focus-workspace", "2"]).
    function action(args) {
        actionProc.command = ["niri", "msg", "action"].concat(args);
        actionProc.running = true;
    }

    function focusWorkspace(ws) {
        // niri references workspaces by index or name; prefer name if set.
        root.action(["focus-workspace", ws.name ? String(ws.name) : String(ws.idx)]);
    }

    function focusWindow(id) {
        actionProc.command = ["niri", "msg", "action", "focus-window", "--id", String(id)];
        actionProc.running = true;
    }

    Process {
        id: actionProc
        running: false
    }

    // Long-lived event stream. If niri restarts, the process exits and we
    // restart it after a short delay.
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
                    // Ignore malformed / partial lines.
                }
            }
        }
        onExited: restartTimer.start()
    }

    Timer {
        id: restartTimer
        interval: 1000
        onTriggered: stream.running = true
    }
}
