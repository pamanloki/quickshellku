import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "root:/services"

// macOS-style Sound panel: volume slider + output/input device pickers.
// Drops from the top-right below the menu bar.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.audioOpen || slide.y > -box.height
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:audio"

        readonly property var sink: Pipewire.defaultAudioSink
        readonly property var source: Pipewire.defaultAudioSource
        readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
        readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

        readonly property var sinks: {
            const ns = (Pipewire.nodes && Pipewire.nodes.values) ? Pipewire.nodes.values : [];
            const out = [];
            for (let i = 0; i < ns.length; i++) {
                const n = ns[i];
                if (n && n.isSink && !n.isStream) out.push(n);
            }
            return out;
        }
        readonly property var sources: {
            const ns = (Pipewire.nodes && Pipewire.nodes.values) ? Pipewire.nodes.values : [];
            const out = [];
            for (let i = 0; i < ns.length; i++) {
                const n = ns[i];
                if (n && n.audio && !n.isSink && !n.isStream) out.push(n);
            }
            return out;
        }
        function nodeName(n) { return n ? (n.description || n.nickname || n.name || "Unknown") : "None"; }
        function setVolume(v) {
            if (!sink || !sink.audio) return;
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, v / 100));
        }

        PwObjectTracker { objects: win.sink ? [win.sink] : [] }
        PwObjectTracker { objects: win.sinks }
        PwObjectTracker { objects: win.sources }

        MouseArea { anchors.fill: parent; onClicked: Globals.audioOpen = false }

        // device row
        component DevRow: Rectangle {
            property string name: ""
            property bool current: false
            signal picked()
            width: parent ? parent.width : 0
            height: 32
            radius: 10
            color: current ? Theme.base02 : (drh.hovered ? Theme.base01 : "transparent")
            Text {
                anchors.left: parent.left; anchors.leftMargin: 12
                anchors.right: chk.left; anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: name
                color: Theme.base05
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                elide: Text.ElideRight
            }
            Text {
                id: chk
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: parent.current ? "󰄬" : ""
                color: Theme.base0B
                font.family: Theme.fontFamilyFallback
                font.pixelSize: Theme.fontSize - 1
            }
            HoverHandler { id: drh }
            MouseArea { anchors.fill: parent; onClicked: parent.picked() }
        }

        Rectangle {
            id: box
            transform: Translate {
                id: slide
                y: Globals.audioOpen ? 0 : -box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }
            width: 340
            height: col.implicitHeight + 28
            x: Globals.panelX < 0
                ? (parent.width - width - 8)
                : Math.max(8, Math.min(parent.width - width - 8, Globals.panelX - width / 2))
            anchors.top: parent.top
            anchors.topMargin: 4
            radius: 20
            color: Theme.base00
            border.width: 1
            border.color: Theme.base02

            MouseArea { anchors.fill: parent }

            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "Sound"
                    color: Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    font.weight: Theme.fontWeight
                }

                // volume slider
                Item {
                    width: parent.width
                    height: 40
                    Rectangle {
                        id: vtrack
                        anchors.fill: parent
                        radius: 13
                        color: Theme.base02
                        Rectangle {
                            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                            radius: vtrack.radius
                            width: Math.max(win.volume > 0 ? 2 * radius : 0, Math.round(parent.width * Math.max(0, Math.min(100, win.volume)) / 100))
                            color: win.muted ? Theme.base08 : Theme.base0D
                        }
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 13
                            anchors.verticalCenter: parent.verticalCenter
                            text: win.muted || win.volume === 0 ? "󰖁" : (win.volume >= 50 ? "󰕾" : "󰖀")
                            color: win.volume > 6 ? Theme.base00 : Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize + 4
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        function pick(mx) { win.setVolume(Math.round(Math.max(0, Math.min(1, mx / width)) * 100)); }
                        onPressed: mouse => pick(mouse.x)
                        onPositionChanged: mouse => { if (pressed) pick(mouse.x); }
                    }
                }

                // output devices
                Text {
                    text: "Output"
                    color: Theme.base04
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 3
                    font.weight: Theme.fontWeight
                    visible: win.sinks.length > 0
                }
                Column {
                    width: parent.width
                    spacing: 2
                    Repeater {
                        model: win.sinks
                        delegate: DevRow {
                            required property var modelData
                            name: win.nodeName(modelData)
                            current: modelData === win.sink
                            onPicked: Pipewire.preferredDefaultAudioSink = modelData
                        }
                    }
                }

                // input devices
                Text {
                    text: "Input"
                    color: Theme.base04
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 3
                    font.weight: Theme.fontWeight
                    visible: win.sources.length > 0
                }
                Column {
                    width: parent.width
                    spacing: 2
                    visible: win.sources.length > 0
                    Repeater {
                        model: win.sources
                        delegate: DevRow {
                            required property var modelData
                            name: win.nodeName(modelData)
                            current: modelData === win.source
                            onPicked: Pipewire.preferredDefaultAudioSource = modelData
                        }
                    }
                }
            }
        }
    }
}
