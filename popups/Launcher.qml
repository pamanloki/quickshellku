import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/services"

// App launcher, polished with ideas from noctalia:
//   * fuzzy scoring (prefix / word-start / substring / subsequence)
//   * "most used" ordering via a small persisted usage count
//   * hover-to-select that ignores stray hover right after keyboard nav
//   * command mode: type ">cmd" and press Enter to run it
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
            s += Math.min(300, (win.usage[e.id] || 0) * 25); // frequency boost
            s -= name.length * 0.1;                            // prefer shorter
            return s;
        }

        function refresh() {
            if (win.commandMode) {
                win.results = [];
                win.selectedIndex = 0;
                return;
            }
            const q = search.text.toLowerCase().trim();
            const apps = DesktopEntries.applications;
            const all = apps && apps.values !== undefined ? apps.values : apps;
            let out = [];
            if (q.length === 0) {
                for (const e of all)
                    if (!e.noDisplay)
                        out.push(e);
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
                if (cmd.length > 0)
                    Quickshell.execDetached(["sh", "-c", cmd]);
                Globals.launcherOpen = false;
                return;
            }
            const e = win.results[win.selectedIndex];
            if (e) {
                win.bumpUsage(e.id);
                e.execute();
                Globals.launcherOpen = false;
            }
        }

        function move(delta) {
            const n = win.results.length;
            if (n === 0) return;
            win.ignoreHover = true;
            win.selectedIndex = Math.max(0, Math.min(n - 1, win.selectedIndex + delta));
            list.positionViewAtIndex(win.selectedIndex, ListView.Contain);
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

        // dim + click-away
        MouseArea { anchors.fill: parent; onClicked: Globals.launcherOpen = false }
        Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.38 }

        Rectangle {
            id: box
            opacity: win.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            transform: Translate { y: win.visible ? 0 : 14; Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
            width: 560
            height: 540
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -40
            color: Theme.base00
            border.color: Theme.base02
            border.width: 2
            radius: 14
            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // ---- search field ----
                Rectangle {
                    width: parent.width
                    height: 46
                    radius: 10
                    color: Theme.base01
                    border.color: search.activeFocus ? Theme.base0D : "transparent"
                    border.width: 2

                    Text {
                        id: searchIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.commandMode ? "󰅱" : ""
                        color: win.commandMode ? Theme.base09 : Theme.base0D
                        font.family: Theme.fontFamilyFallback
                        font.pixelSize: Theme.fontSize + 2
                    }
                    TextInput {
                        id: search
                        anchors.left: searchIcon.right
                        anchors.leftMargin: 12
                        anchors.right: countText.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.base05
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        clip: true
                        onTextChanged: win.refresh()

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search apps…  (type > to run a command)"
                            color: Theme.base03
                            font: search.font
                            visible: search.text.length === 0
                        }

                        Keys.onEscapePressed: Globals.launcherOpen = false
                        Keys.onReturnPressed: win.activate()
                        Keys.onEnterPressed: win.activate()
                        Keys.onDownPressed: win.move(1)
                        Keys.onUpPressed: win.move(-1)
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Tab) { win.move(1); event.accepted = true; }
                            else if (event.key === Qt.Key_Backtab) { win.move(-1); event.accepted = true; }
                        }
                    }
                    Text {
                        id: countText
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.commandMode ? "run" : win.results.length + ""
                        color: Theme.base03
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }
                }

                // ---- results ----
                ListView {
                    id: list
                    width: parent.width
                    height: parent.height - 46 - 12 - 22 - 12
                    clip: true
                    model: win.commandMode ? 0 : win.results
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 2
                    cacheBuffer: 400

                    // command-mode hint
                    Text {
                        anchors.centerIn: parent
                        visible: win.commandMode
                        text: search.text.length > 1
                            ? ("Press ↵ to run:  " + search.text.slice(1).trim())
                            : "Type a shell command…"
                        color: Theme.base04
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                    // empty state
                    Text {
                        anchors.centerIn: parent
                        visible: !win.commandMode && win.results.length === 0
                        text: "No matches"
                        color: Theme.base03
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        width: list.width
                        height: 52
                        radius: 8
                        readonly property bool selected: index === win.selectedIndex
                        color: selected ? Theme.base02 : "transparent"
                        Behavior on color { ColorAnimation { duration: 90 } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 40; height: 40; radius: 8
                                color: row.selected ? Theme.base01 : "transparent"
                                Image {
                                    anchors.centerIn: parent
                                    width: 30; height: 30
                                    sourceSize.width: 30; sourceSize.height: 30
                                    source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                                    fillMode: Image.PreserveAspectFit
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: row.width - 90
                                spacing: 1
                                Text {
                                    text: row.modelData.name || ""
                                    color: Theme.base05
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.weight: Theme.fontWeight
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: row.modelData.genericName || row.modelData.comment || ""
                                    color: Theme.base04
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 3
                                    visible: text.length > 0
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onPositionChanged: {
                                win.ignoreHover = false;
                                win.selectedIndex = row.index;
                            }
                            onEntered: if (!win.ignoreHover) win.selectedIndex = row.index
                            onClicked: { win.selectedIndex = row.index; win.activate(); }
                        }
                    }
                }

                // ---- footer hints ----
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "↑↓ navigate    ↵ open    esc close"
                    color: Theme.base03
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 4
                }
            }
        }
    }
}
