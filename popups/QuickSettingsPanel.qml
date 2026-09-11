import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "root:/services"

// Control Center, macOS-style: a grid of rounded modules (connectivity,
// Focus/Night Light tiles, Display + Sound sliders, Now Playing) — no swipe.
// Solid theme colours, no glass/blur.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.quickSettingsOpen || slide.y > -box.height
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:quicksettings"

        // ---- audio ----
        readonly property var sink: Pipewire.defaultAudioSink
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
        property bool audioExpanded: false
        function nodeName(n) { return n ? (n.description || n.nickname || n.name || "Unknown") : "None"; }
        function setVolume(v) {
            if (!sink || !sink.audio) return;
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, v / 100));
        }

        PwObjectTracker { objects: win.sink ? [win.sink] : [] }
        PwObjectTracker { objects: win.sinks }

        onVisibleChanged: if (visible) {
            audioExpanded = false;
            Network.refresh(); Bluetooth.refresh(); Nightlight.refresh();
            Player.refreshPosition();
        }

        MouseArea { anchors.fill: parent; onClicked: Globals.quickSettingsOpen = false }

        // ============ components ============

        // a rounded module container
        component Card: Rectangle {
            radius: 14
            color: Theme.base01
        }

        // connectivity row: round icon (toggles) + label/sublabel (opens panel)
        component ConnRow: Item {
            property string icon: ""
            property string label: ""
            property string sub: ""
            property bool on: false
            property color accent: Theme.base0D
            signal toggled()
            signal opened()
            width: parent ? parent.width : 0
            height: 46
            Rectangle {
                id: ci
                width: 34; height: 34; radius: 17
                anchors.left: parent.left; anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                color: on ? accent : Theme.base03
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: icon
                    color: on ? Theme.base00 : Theme.base05
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: Theme.fontSize + 1
                }
                MouseArea { anchors.fill: parent; onClicked: toggled() }
            }
            Column {
                anchors.left: ci.right; anchors.leftMargin: 12
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Text {
                    text: label
                    color: Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: Theme.fontWeight
                }
                Text {
                    text: sub
                    color: Theme.base04
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 4
                    elide: Text.ElideRight
                    width: parent.width
                    visible: sub.length > 0
                }
            }
            MouseArea {
                anchors.left: ci.right; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right
                onClicked: opened()
            }
        }

        // square-ish toggle tile (Focus / Night Light)
        component Tile: Rectangle {
            property string icon: ""
            property string label: ""
            property string state: ""
            property bool on: false
            property color accent: Theme.base0E
            signal toggled()
            signal opened()
            height: 62
            radius: 14
            color: on ? accent : Theme.base01
            Behavior on color { ColorAnimation { duration: 120 } }
            Column {
                anchors.left: parent.left; anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text {
                    text: icon
                    color: on ? Theme.base00 : Theme.base05
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: Theme.fontSize + 4
                }
                Text {
                    text: label
                    color: on ? Theme.base00 : Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 3
                    font.weight: Theme.fontWeight
                }
                Text {
                    text: state
                    color: on ? Theme.base00 : Theme.base04
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 4
                }
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => mouse.button === Qt.RightButton ? opened() : toggled()
            }
        }

        // horizontal slider inside a card
        component HSlider: Item {
            property string icon: ""
            property real value: 0        // 0..100
            property color accent: Theme.base0D
            signal moved(real v)
            height: 44
            Rectangle {
                id: track
                anchors.fill: parent
                radius: height / 2
                color: Theme.base02
                Rectangle {
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                    radius: track.radius
                    width: Math.max(height, track.width * Math.max(0, Math.min(100, value)) / 100)
                    color: accent
                    Behavior on width { NumberAnimation { duration: 60 } }
                }
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: icon
                    color: Theme.base00
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: Theme.fontSize + 4
                }
            }
            MouseArea {
                anchors.fill: parent
                preventStealing: true
                function pick(mx) { moved(Math.round(Math.max(0, Math.min(1, mx / width)) * 100)); }
                onPressed: mouse => pick(mouse.x)
                onPositionChanged: mouse => { if (pressed) pick(mouse.x); }
            }
        }

        Rectangle {
            id: box
            transform: Translate {
                id: slide
                y: Globals.quickSettingsOpen ? 0 : -box.height
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
                anchors.margins: 14
                spacing: 10

                Text {
                    text: "Control Centre"
                    color: Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                    bottomPadding: 2
                }

                // ---- connectivity ----
                Card {
                    width: parent.width
                    height: conn.implicitHeight + 8
                    Column {
                        id: conn
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        ConnRow {
                            width: parent.width
                            icon: "󰤨"; label: "Wi-Fi"
                            on: Network.radioOn
                            accent: Theme.base0D
                            sub: Network.connected ? Network.ssid : (Network.radioOn ? "On" : "Off")
                            onToggled: Network.setRadio(!Network.radioOn)
                            onOpened: Globals.toggleWifi()
                        }
                        ConnRow {
                            width: parent.width
                            icon: "󰂯"; label: "Bluetooth"
                            on: Bluetooth.powered
                            accent: Theme.base0D
                            sub: Bluetooth.powered ? (Bluetooth.connectedName || "On") : "Off"
                            onToggled: Bluetooth.setPowered(!Bluetooth.powered)
                            onOpened: Globals.toggleBluetooth()
                        }
                    }
                }

                // ---- Night Light + Do Not Disturb tiles ----
                Row {
                    width: parent.width
                    spacing: 10
                    Tile {
                        width: (parent.width - 10) / 2
                        icon: "󰛨"; label: "Night Light"
                        state: Nightlight.active ? "On" : "Off"
                        on: Nightlight.active
                        accent: Theme.base09
                        onToggled: Nightlight.active ? Nightlight.disable() : Nightlight.enable()
                        onOpened: Globals.toggleNightlight()
                    }
                    Tile {
                        width: (parent.width - 10) / 2
                        icon: Notifications.doNotDisturb ? "󰂛" : "󰂚"; label: "Do Not Disturb"
                        state: Notifications.doNotDisturb ? "On" : "Off"
                        on: Notifications.doNotDisturb
                        accent: Theme.base0E
                        onToggled: Notifications.doNotDisturb = !Notifications.doNotDisturb
                    }
                }

                // ---- Wallpaper + Theme ----
                Row {
                    width: parent.width
                    spacing: 10
                    Tile {
                        width: (parent.width - 10) / 2
                        icon: "󰸉"; label: "Wallpaper"; state: "Choose"
                        accent: Theme.base0C
                        onToggled: Globals.toggleWallpaper()
                    }
                    Tile {
                        width: (parent.width - 10) / 2
                        icon: "󰸌"; label: "Theme"; state: "Flavours"
                        accent: Theme.base0E
                        onToggled: Globals.toggleTheme()
                    }
                }

                // ---- Display ----
                Card {
                    width: parent.width
                    height: 74
                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6
                        Text {
                            text: "Display"
                            color: Theme.base05
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                            font.weight: Theme.fontWeight
                        }
                        HSlider {
                            width: parent.width
                            icon: "󰃟"
                            value: Brightness.percent
                            accent: Theme.base0D
                            onMoved: v => Brightness.set(v)
                        }
                    }
                }

                // ---- Sound ----
                Card {
                    width: parent.width
                    height: sndCol.implicitHeight + 24
                    Column {
                        id: sndCol
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 6
                        Row {
                            width: parent.width
                            Text {
                                text: "Sound"
                                color: Theme.base05
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 3
                                font.weight: Theme.fontWeight
                                width: parent.width - 24
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: win.audioExpanded ? "󰅃" : "󰅀"
                                color: Theme.base04
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: Theme.fontSize
                                anchors.verticalCenter: parent.verticalCenter
                                MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: win.audioExpanded = !win.audioExpanded }
                            }
                        }
                        HSlider {
                            width: parent.width
                            icon: win.muted || win.volume === 0 ? "󰖁" : (win.volume >= 50 ? "󰕾" : "󰖀")
                            value: win.volume
                            accent: win.muted ? Theme.base08 : Theme.base0D
                            onMoved: v => win.setVolume(v)
                        }
                        // output device switcher
                        Column {
                            width: parent.width
                            spacing: 2
                            visible: win.audioExpanded
                            Repeater {
                                model: win.sinks
                                delegate: Rectangle {
                                    required property var modelData
                                    width: parent.width
                                    height: 30
                                    radius: 8
                                    readonly property bool current: modelData === win.sink
                                    color: current ? Theme.base02 : (devMA.containsMouse ? Theme.base02 : "transparent")
                                    Text {
                                        anchors.left: parent.left; anchors.leftMargin: 10
                                        anchors.right: chk.left; anchors.rightMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: win.nodeName(modelData)
                                        color: Theme.base05
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize - 3
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        id: chk
                                        anchors.right: parent.right; anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: parent.current ? "󰄬" : ""
                                        color: Theme.base0B
                                        font.family: Theme.fontFamilyFallback
                                        font.pixelSize: Theme.fontSize - 2
                                    }
                                    MouseArea {
                                        id: devMA
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: Pipewire.preferredDefaultAudioSink = modelData
                                    }
                                }
                            }
                        }
                    }
                }

            }
        }
    }
}
