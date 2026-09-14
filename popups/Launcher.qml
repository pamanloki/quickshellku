import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/services"

// macOS Launchpad-style app launcher: a full-screen grid of large app icons
// with a search pill on top. Keeps fuzzy scoring + "most used" ordering, and
// the command mode (">cmd") / clipboard mode (";") from before.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.launcherOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:launcher"

        property var results: []
        property int selectedIndex: 0
        property bool ignoreHover: true
        property var usage: ({})

        readonly property bool commandMode: search.text.startsWith(">")
        readonly property bool clipMode: search.text.startsWith(";")
        property var clipResults: []   // [{id, preview}] from cliphist

        // ---------- clipboard history (cliphist) ----------
        function copyClip(id) {
            clipCopyProc.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", String(id)];
            clipCopyProc.running = true;
        }
        Process { id: clipCopyProc }
        Process {
            id: clipListProc
            command: ["sh", "-c", "cliphist list 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const q = search.text.slice(1).toLowerCase().trim();
                    const out = [];
                    for (const l of text.split("\n")) {
                        if (!l.length) continue;
                        const tab = l.indexOf("\t");
                        const id = tab >= 0 ? l.slice(0, tab) : l;
                        const preview = tab >= 0 ? l.slice(tab + 1) : l;
                        if (!q || preview.toLowerCase().indexOf(q) >= 0)
                            out.push({ id: id, preview: preview });
                    }
                    win.clipResults = out;
                    win.selectedIndex = 0;
                }
            }
        }

        // ---------- usage persistence ----------
        property string usagePath: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshellku/launcher_usage.json"

        FileView {
            id: usageFile
            path: win.usagePath
            printErrors: false
            onLoaded: {
                try { win.usage = JSON.parse(text() || "{}"); } catch (e) { win.usage = {}; }
            }
        }
        Process { id: saveProc }
        function bumpUsage(id) {
            if (!id) return;
            const u = win.usage;
            u[id] = (u[id] || 0) + 1;
            win.usage = u;
            saveProc.command = ["sh", "-c",
                "mkdir -p \"$(dirname \"$1\")\"; printf %s \"$2\" > \"$1\"",
                "sh", win.usagePath, JSON.stringify(u)];
            saveProc.running = true;
        }

        // ---------- fuzzy scoring ----------
        function _subseq(q, s) {
            let i = 0;
            for (let k = 0; k < s.length && i < q.length; k++)
                if (s[k] === q[i]) i++;
            return i >= q.length;
        }
        function _score(q, e) {
            const name = (e.name || "").toLowerCase();
            const gen = (e.genericName || "").toLowerCase();
            const com = (e.comment || "").toLowerCase();
            let s;
            if (name.startsWith(q)) s = 1000;
            else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) s = 720;
            else if (name.indexOf(q) >= 0) s = 560 - name.indexOf(q);
            else if (_subseq(q, name)) s = 300;
            else if (gen.indexOf(q) >= 0) s = 220;
            else if (com.indexOf(q) >= 0) s = 140;
            else return -1;
            s += Math.min(300, (win.usage[e.id] || 0) * 25);
            s -= name.length * 0.1;
            return s;
        }

        function refresh() {
            if (win.commandMode) { win.results = []; win.selectedIndex = 0; return; }
            if (win.clipMode) { clipListProc.running = true; return; }
            const q = search.text.toLowerCase().trim();
            const apps = DesktopEntries.applications;
            const all = apps && apps.values !== undefined ? apps.values : apps;
            let out = [];
            if (q.length === 0) {
                for (const e of all) if (!e.noDisplay) out.push(e);
                out.sort((a, b) => {
                    const ua = win.usage[a.id] || 0, ub = win.usage[b.id] || 0;
                    if (ua !== ub) return ub - ua;
                    return (a.name || "").localeCompare(b.name || "");
                });
            } else {
                const scored = [];
                for (const e of all) {
                    if (e.noDisplay) continue;
                    const sc = win._score(q, e);
                    if (sc >= 0) scored.push({ e: e, s: sc });
                }
                scored.sort((a, b) => b.s - a.s);
                out = scored.map(x => x.e);
            }
            win.results = out;
            win.selectedIndex = 0;
        }

        function activate() {
            if (win.commandMode) {
                const cmd = search.text.slice(1).trim();
                if (cmd.length > 0) Quickshell.execDetached(["sh", "-c", cmd]);
                Globals.launcherOpen = false;
                return;
            }
            if (win.clipMode) {
                const c = win.clipResults[win.selectedIndex];
                if (c) win.copyClip(c.id);
                Globals.launcherOpen = false;
                return;
            }
            const e = win.results[win.selectedIndex];
            if (e) { win.bumpUsage(e.id); e.execute(); Globals.launcherOpen = false; }
        }

        function move(delta) {
            const n = win.clipMode ? win.clipResults.length : win.results.length;
            if (n === 0) return;
            win.ignoreHover = true;
            win.selectedIndex = Math.max(0, Math.min(n - 1, win.selectedIndex + delta));
            if (win.clipMode) clipList.positionViewAtIndex(win.selectedIndex, ListView.Contain);
            else grid.positionViewAtIndex(win.selectedIndex, GridView.Contain);
        }

        onVisibleChanged: {
            if (visible) {
                usageFile.reload();
                search.text = "";
                ignoreHover = true;
                refresh();
                search.forceActiveFocus();
            }
        }

        // dim + click-away (full screen, Launchpad-style)
        MouseArea { anchors.fill: parent; onClicked: Globals.launcherOpen = false }
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: win.visible ? 0.78 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects } }
        }

        Item {
            id: box
            anchors.fill: parent
            opacity: win.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.OutCubic } }
            scale: win.visible ? 1 : 0.96
            Behavior on scale { NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpatial } }

            // ---- search pill (top centre) ----
            Rectangle {
                id: searchPill
                anchors.top: parent.top
                anchors.topMargin: Math.round(parent.height * 0.10)
                anchors.horizontalCenter: parent.horizontalCenter
                width: 420
                height: 44
                radius: 22
                color: Theme.base01
                border.color: search.activeFocus ? Theme.accent : Theme.base02
                border.width: 1

                Text {
                    id: searchIcon
                    anchors.left: parent.left; anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.clipMode ? "󰅍" : win.commandMode ? "󰅱" : ""
                    color: win.clipMode ? Theme.accent : win.commandMode ? Theme.accent : Theme.base04
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: Theme.fontSize + 2
                }
                TextInput {
                    id: search
                    anchors.left: searchIcon.right; anchors.leftMargin: 12
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 1
                    clip: true
                    onTextChanged: win.refresh()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search"
                        color: Theme.base03
                        font: search.font
                        visible: search.text.length === 0
                    }

                    Keys.onEscapePressed: Globals.launcherOpen = false
                    Keys.onReturnPressed: win.activate()
                    Keys.onEnterPressed: win.activate()
                    Keys.onDownPressed: win.move(win.clipMode ? 1 : grid.columns)
                    Keys.onUpPressed: win.move(win.clipMode ? -1 : -grid.columns)
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Tab) { win.move(1); event.accepted = true; }
                        else if (event.key === Qt.Key_Backtab) { win.move(-1); event.accepted = true; }
                        else if (event.key === Qt.Key_Right && !win.clipMode) { win.move(1); event.accepted = true; }
                        else if (event.key === Qt.Key_Left && !win.clipMode) { win.move(-1); event.accepted = true; }
                    }
                }
            }

            // ---- command-mode hint ----
            Text {
                anchors.top: searchPill.bottom; anchors.topMargin: 40
                anchors.horizontalCenter: parent.horizontalCenter
                visible: win.commandMode
                text: search.text.length > 1 ? ("Press ↵ to run:  " + search.text.slice(1).trim()) : "Type a shell command…"
                color: Theme.base04
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 1
            }

            // ---- app grid (Launchpad) ----
            GridView {
                id: grid
                visible: !win.clipMode && !win.commandMode
                anchors.top: searchPill.bottom; anchors.topMargin: 28
                anchors.bottom: parent.bottom; anchors.bottomMargin: 40
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width - 120, columns * cellWidth)
                clip: true
                cellWidth: 132
                cellHeight: 124
                readonly property int columns: Math.max(1, Math.floor((parent.width - 120) / cellWidth))
                model: win.results
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 600

                Text {
                    anchors.centerIn: parent
                    visible: win.results.length === 0
                    text: "No matches"
                    color: Theme.base04
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 1
                }

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    width: grid.cellWidth
                    height: grid.cellHeight
                    readonly property bool selected: index === win.selectedIndex

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        height: parent.height - 8
                        radius: 18
                        color: cell.selected ? Theme.base02 : "transparent"
                        Behavior on color { ColorAnimation { duration: 90 } }
                    }
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 60; height: 60
                            sourceSize.width: 60; sourceSize.height: 60
                            source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                            fillMode: Image.PreserveAspectFit
                        }
                        Text {
                            width: grid.cellWidth - 16
                            horizontalAlignment: Text.AlignHCenter
                            text: cell.modelData.name || ""
                            color: Theme.base05
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.WordWrap
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: { win.ignoreHover = false; win.selectedIndex = cell.index; }
                        onEntered: if (!win.ignoreHover) win.selectedIndex = cell.index
                        onClicked: { win.selectedIndex = cell.index; win.activate(); }
                    }
                }
            }

            // ---- clipboard results (list) ----
            ListView {
                id: clipList
                visible: win.clipMode
                anchors.top: searchPill.bottom; anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                width: 560
                height: Math.min(parent.height - searchPill.height - 160, contentHeight)
                clip: true
                model: win.clipResults
                boundsBehavior: Flickable.StopAtBounds
                spacing: 2
                cacheBuffer: 400

                Text {
                    anchors.centerIn: parent
                    visible: win.clipMode && win.clipResults.length === 0
                    text: "Clipboard empty\n(needs cliphist + wl-clipboard)"
                    color: Theme.base03
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    horizontalAlignment: Text.AlignHCenter
                }

                delegate: Rectangle {
                    id: crow
                    required property var modelData
                    required property int index
                    width: clipList.width
                    height: 44
                    radius: 10
                    readonly property bool selected: index === win.selectedIndex
                    color: selected ? Theme.base02 : Theme.base01
                    Behavior on color { ColorAnimation { duration: 90 } }

                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 14
                        anchors.right: parent.right; anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: crow.modelData.preview
                        color: Theme.base05
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: { win.ignoreHover = false; win.selectedIndex = crow.index; }
                        onEntered: if (!win.ignoreHover) win.selectedIndex = crow.index
                        onClicked: { win.selectedIndex = crow.index; win.activate(); }
                    }
                }
            }
        }
    }
}
