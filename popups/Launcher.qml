import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Fuzzel-style app launcher. Reads .desktop entries, fuzzy-ish filter,
// keyboard driven (type to search, Up/Down, Enter, Esc).
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

        function refresh() {
            const q = search.text.toLowerCase().trim();
            const apps = DesktopEntries.applications;
            const all = apps && apps.values !== undefined ? apps.values : apps;
            const out = [];
            for (const e of all) {
                if (e.noDisplay)
                    continue;
                const name = (e.name || "").toLowerCase();
                const gen = (e.genericName || "").toLowerCase();
                if (q.length === 0 || name.includes(q) || gen.includes(q))
                    out.push(e);
            }
            out.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
            win.results = out;
            list.currentIndex = out.length > 0 ? 0 : -1;
        }

        function launch(entry) {
            if (entry) {
                entry.execute();
                Globals.launcherOpen = false;
            }
        }

        onVisibleChanged: {
            if (visible) {
                search.text = "";
                refresh();
                search.forceActiveFocus();
            }
        }

        // Dim background; click outside closes.
        MouseArea {
            anchors.fill: parent
            onClicked: Globals.launcherOpen = false
        }
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.35
        }

        Rectangle {
            id: box
            width: 520
            height: 460
            anchors.centerIn: parent
            color: Theme.base00
            border.color: Theme.base02
            border.width: 2
            radius: 6

            // Swallow clicks so they don't hit the closing overlay.
            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Rectangle {
                    width: parent.width
                    height: 40
                    color: Theme.base01
                    radius: 4
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 8
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            color: Theme.base0D
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize
                        }
                        TextInput {
                            id: search
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 40
                            color: Theme.base05
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            clip: true
                            onTextChanged: win.refresh()

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search apps…"
                                color: Theme.base03
                                font: search.font
                                visible: search.text.length === 0
                            }

                            Keys.onEscapePressed: Globals.launcherOpen = false
                            Keys.onReturnPressed: win.launch(win.results[list.currentIndex])
                            Keys.onEnterPressed: win.launch(win.results[list.currentIndex])
                            Keys.onDownPressed: {
                                if (list.currentIndex < win.results.length - 1)
                                    list.currentIndex++;
                            }
                            Keys.onUpPressed: {
                                if (list.currentIndex > 0)
                                    list.currentIndex--;
                            }
                        }
                    }
                }

                ListView {
                    id: list
                    width: parent.width
                    height: parent.height - 50
                    clip: true
                    model: win.results
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: list.width
                        height: 44
                        color: index === list.currentIndex ? Theme.base02 : "transparent"
                        radius: 4

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            spacing: 10
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 28
                                sourceSize.width: 28
                                sourceSize.height: 28
                                source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                fillMode: Image.PreserveAspectFit
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    text: modelData.name || ""
                                    color: Theme.base05
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.weight: Theme.fontWeight
                                }
                                Text {
                                    text: modelData.genericName || modelData.comment || ""
                                    color: Theme.base03
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 3
                                    visible: text.length > 0
                                    elide: Text.ElideRight
                                    width: box.width - 90
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                list.currentIndex = index;
                                win.launch(modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
