import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/services"

// macOS Spotlight: a centred search field (⌘-Space / menu-bar magnifier) with a
// compact results list — apps + a quick calculator. Separate from Launchpad
// (the dock grid). No blur; a cheap layered shadow gives the floating look.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.spotlightOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:spotlight"

        property var results: []       // [{kind:"app"|"calc", entry?, text?, sub?}]
        property int selectedIndex: 0

        onVisibleChanged: {
            if (visible) { search.text = ""; win.refresh(); search.forceActiveFocus(); }
        }

        // ---------- calculator ----------
        function _calc(q) {
            const s = q.trim();
            if (!/[0-9]/.test(s) || !/^[-0-9+*/.()%\s]+$/.test(s)) return null;
            if (!/[-+*/%]/.test(s)) return null;              // needs an operator
            try {
                const r = Function('"use strict"; return (' + s + ')')();
                if (typeof r === "number" && isFinite(r))
                    return (Math.round(r * 1e6) / 1e6).toString();
            } catch (e) {}
            return null;
        }

        // ---------- fuzzy scoring (compact) ----------
        function _subseq(q, s) {
            let i = 0;
            for (let k = 0; k < s.length && i < q.length; k++)
                if (s[k] === q[i]) i++;
            return i >= q.length;
        }
        function _score(q, e) {
            const name = (e.name || "").toLowerCase();
            if (name.startsWith(q)) return 1000 - name.length * 0.1;
            if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 720;
            if (name.indexOf(q) >= 0) return 560 - name.indexOf(q);
            if (_subseq(q, name)) return 300;
            const gen = (e.genericName || "").toLowerCase();
            if (gen.indexOf(q) >= 0) return 220;
            return -1;
        }

        function refresh() {
            const q = search.text.toLowerCase().trim();
            const out = [];
            const calc = win._calc(search.text);
            if (calc !== null) out.push({ kind: "calc", text: "= " + calc, sub: search.text.trim(), value: calc });

            if (q.length > 0) {
                const apps = DesktopEntries.applications;
                const all = apps && apps.values !== undefined ? apps.values : apps;
                const scored = [];
                for (const e of all) {
                    if (e.noDisplay) continue;
                    const sc = win._score(q, e);
                    if (sc >= 0) scored.push({ e: e, s: sc });
                }
                scored.sort((a, b) => b.s - a.s);
                for (let i = 0; i < Math.min(scored.length, 6); i++)
                    out.push({ kind: "app", entry: scored[i].e });
            }
            win.results = out;
            win.selectedIndex = 0;
        }

        function activate(i) {
            const r = win.results[i];
            if (!r) return;
            if (r.kind === "app") { r.entry.execute(); Globals.spotlightOpen = false; }
            else if (r.kind === "calc") {
                Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", r.value]);
                Globals.spotlightOpen = false;
            }
        }

        MouseArea { anchors.fill: parent; onClicked: Globals.spotlightOpen = false }

        // dim
        Rectangle {
            anchors.fill: parent
            color: Theme.base00
            opacity: Globals.spotlightOpen ? 0.45 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects } }
        }

        Item {
            id: cardWrap
            width: 620
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.22
            height: card.height

            // cheap layered soft shadow (no shader)
            Rectangle {
                anchors.centerIn: card
                width: card.width + 26; height: card.height + 26
                radius: 22; color: "#40000000"
            }
            Rectangle {
                anchors.centerIn: card
                anchors.verticalCenterOffset: 6
                width: card.width + 14; height: card.height + 14
                radius: 20; color: "#50000000"
            }

            Rectangle {
                id: card
                width: parent.width
                height: field.height + (win.results.length > 0 ? list.height + 8 : 0)
                radius: 16
                color: Theme.base00
                border.width: 1
                border.color: Theme.base02

                MouseArea { anchors.fill: parent }   // swallow clicks inside

                // search field
                Item {
                    id: field
                    width: parent.width
                    height: 60
                    Text {
                        id: mag
                        anchors.left: parent.left; anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""
                        color: Theme.base04
                        font.family: Theme.fontFamilyFallback
                        font.pixelSize: Theme.fontSize + 6
                    }
                    TextInput {
                        id: search
                        anchors.left: mag.right; anchors.leftMargin: 14
                        anchors.right: parent.right; anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.base05
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 8
                        clip: true
                        onTextChanged: win.refresh()
                        Keys.onEscapePressed: Globals.spotlightOpen = false
                        Keys.onDownPressed: if (win.results.length) win.selectedIndex = Math.min(win.selectedIndex + 1, win.results.length - 1)
                        Keys.onUpPressed: if (win.results.length) win.selectedIndex = Math.max(win.selectedIndex - 1, 0)
                        Keys.onReturnPressed: win.activate(win.selectedIndex)
                        Keys.onEnterPressed: win.activate(win.selectedIndex)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Spotlight Search"
                            color: Theme.base03
                            font: search.font
                            visible: search.text.length === 0
                        }
                    }
                }

                // results
                Column {
                    id: list
                    anchors.top: field.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    visible: win.results.length > 0

                    Repeater {
                        model: win.results
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: list.width
                            height: 46
                            radius: 10
                            color: index === win.selectedIndex ? Theme.accent : (rowH.hovered ? Theme.base02 : "transparent")

                            Image {
                                id: rIcon
                                visible: modelData.kind === "app"
                                anchors.left: parent.left; anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30; height: 30
                                sourceSize.width: 30; sourceSize.height: 30
                                source: modelData.kind === "app"
                                    ? Quickshell.iconPath(modelData.entry.icon || modelData.entry.id, "application-x-executable")
                                    : ""
                                fillMode: Image.PreserveAspectFit
                            }
                            Text {
                                visible: modelData.kind === "calc"
                                anchors.left: parent.left; anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰃬"
                                color: index === win.selectedIndex ? Theme.base00 : Theme.base05
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: Theme.fontSize + 6
                            }
                            Text {
                                anchors.left: rIcon.right; anchors.leftMargin: 12
                                anchors.right: parent.right; anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.kind === "app" ? modelData.entry.name : modelData.text
                                color: index === win.selectedIndex ? Theme.base00 : Theme.base05
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.weight: Theme.fontWeight
                                elide: Text.ElideRight
                            }
                            HoverHandler { id: rowH }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { win.selectedIndex = index; win.activate(index); }
                            }
                        }
                    }
                }
            }
        }
    }
}
