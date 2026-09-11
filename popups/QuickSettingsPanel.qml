import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "root:/services"

// Quick settings: volume + brightness sliders and WiFi / Bluetooth / Night
// light tiles. Styled after noctalia (icon badge + rounded slider with a
// cut-out knob + value; big rounded toggle tiles).
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.quickSettingsOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:quicksettings"

        readonly property var sink: Pipewire.defaultAudioSink
        readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
        readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

        // Audio output devices (real sinks, not per-app streams) for the switcher.
        readonly property var sinks: {
            const ns = (Pipewire.nodes && Pipewire.nodes.values) ? Pipewire.nodes.values : [];
            const out = [];
            for (let i = 0; i < ns.length; i++) {
                const n = ns[i];
                if (n && n.isSink && !n.isStream)
                    out.push(n);
            }
            return out;
        }
        property bool audioExpanded: false
        function nodeName(n) {
            return n ? (n.description || n.nickname || n.name || "Unknown") : "None";
        }

        PwObjectTracker { objects: win.sink ? [win.sink] : [] }
        PwObjectTracker { objects: win.sinks }

        function setVolume(v) {
            if (!sink || !sink.audio) return;
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, v / 100));
        }

        onVisibleChanged: if (visible) { audioExpanded = false; Network.refresh(); Bluetooth.refresh(); Nightlight.refresh(); }

        // ---------- slider row: icon badge + track + value ----------
        component CtlSlider: Item {
            id: sl
            property string icon: ""
            property int value: 0
            property color accent: Theme.base0D
            property bool badgeActive: false
            signal moved(int v)
            signal badgeClicked()
            width: parent ? parent.width : 0
            height: 40
            property bool dragging: false

            Rectangle {
                id: badge
                width: 38; height: 38; radius: 19
                anchors.verticalCenter: parent.verticalCenter
                color: sl.badgeActive ? sl.accent : Theme.base02
                Text {
                    anchors.centerIn: parent
                    text: sl.icon
                    color: sl.badgeActive ? Theme.base00 : sl.accent
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: Theme.fontSize + 5
                }
                MouseArea { anchors.fill: parent; onClicked: sl.badgeClicked() }
            }

            Item {
                id: track
                anchors.left: badge.right
                anchors.leftMargin: 12
                anchors.right: valLabel.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                height: 40

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 8; radius: 4
                    color: Theme.base02
                    Rectangle {
                        height: parent.height; radius: 4
                        width: Math.round(parent.width * Math.max(0, Math.min(100, sl.value)) / 100)
                        color: sl.accent
                    }
                }
                Rectangle {
                    id: knob
                    width: knobHover.hovered || sl.dragging ? 22 : 18
                    height: width; radius: width / 2
                    color: sl.accent
                    border.color: Theme.base00
                    border.width: 3
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.round((parent.width - width) * Math.max(0, Math.min(100, sl.value)) / 100)
                    Behavior on width { NumberAnimation { duration: 80 } }
                    HoverHandler { id: knobHover }
                }
                MouseArea {
                    anchors.fill: parent
                    function pick(mx) {
                        const v = Math.round(Math.max(0, Math.min(1, mx / track.width)) * 100);
                        sl.value = v; sl.moved(v);
                    }
                    onPressed: mouse => { sl.dragging = true; pick(mouse.x); }
                    onPositionChanged: mouse => { if (sl.dragging) pick(mouse.x); }
                    onReleased: sl.dragging = false
                }
            }

            Text {
                id: valLabel
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 46
                horizontalAlignment: Text.AlignRight
                text: sl.value + "%"
                color: Theme.base05
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
                font.features: ({ "tnum": 1 })
            }
        }

        // ---------- toggle tile ----------
        component Tile: Rectangle {
            id: tile
            property string icon: ""
            property string label: ""
            property color accent: Theme.base0D
            property bool on: false
            signal toggled()
            signal opened()
            width: (contentCol.width - 2 * 10) / 3
            height: 88
            radius: 14
            color: on ? accent : Theme.base02
            Behavior on color { ColorAnimation { duration: 120 } }

            Column {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tile.icon
                    color: tile.on ? Theme.base00 : tile.accent
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: Theme.fontSize + 9
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tile.label
                    color: tile.on ? Theme.base00 : Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 4
                    elide: Text.ElideRight
                    width: tile.width - 12
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => mouse.button === Qt.RightButton ? tile.opened() : tile.toggled()
            }
        }

        MouseArea { anchors.fill: parent; onClicked: Globals.quickSettingsOpen = false }

        Item {
            id: box
            opacity: win.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEffects } }
            transformOrigin: Item.BottomRight
            scale: win.visible ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpatial } }
            width: 380
            height: contentCol.implicitHeight + 36
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 8
            anchors.bottomMargin: 0
            IslandBg { anchors.fill: parent; radius: 16 }
            MouseArea { anchors.fill: parent }

            Column {
                id: contentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 16

                // date + theme button
                Row {
                    width: parent.width
                    Column {
                        width: parent.width - 92
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text {
                            text: Qt.formatDate(Time.now, "dddd")
                            color: Theme.base05
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 2
                            font.weight: Theme.fontWeight
                        }
                        Text {
                            text: Qt.formatDate(Time.now, "d MMMM yyyy")
                            color: Theme.base05
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                        }
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: wallH.hovered ? Theme.base02 : Theme.base01
                            Text {
                                anchors.centerIn: parent
                                text: "󰸉"
                                color: Theme.base0C
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: Theme.fontSize + 4
                            }
                            HoverHandler { id: wallH }
                            MouseArea { anchors.fill: parent; onClicked: Globals.toggleWallpaper() }
                        }
                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: themeH.hovered ? Theme.base02 : Theme.base01
                            Text {
                                anchors.centerIn: parent
                                text: "󰸌"
                                color: Theme.base0E
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: Theme.fontSize + 4
                            }
                            HoverHandler { id: themeH }
                            MouseArea { anchors.fill: parent; onClicked: Globals.toggleTheme() }
                        }
                    }
                }

                // music player (only when something is playing/paused)
                Rectangle {
                    width: parent.width
                    height: 88
                    radius: 12
                    color: Theme.base01
                    visible: Player.hasPlayer

                    // Keep the MPRIS position fresh while this panel is open and
                    // playing (MPRIS doesn't push it). Only runs when visible, so
                    // there's no background ticking.
                    Timer {
                        interval: 1000
                        running: win.visible && Player.isPlaying
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: Player.refreshPosition()
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 8

                        Row {
                            width: parent.width
                            height: 48
                            spacing: 10

                            Rectangle {
                                width: 48; height: 48; radius: 8
                                anchors.verticalCenter: parent.verticalCenter
                                color: Theme.base02
                                clip: true
                                Image {
                                    anchors.fill: parent
                                    source: Player.artUrl
                                    fillMode: Image.PreserveAspectCrop
                                    visible: Player.artUrl.length > 0
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: Player.artUrl.length === 0
                                    text: "󰝚"
                                    color: Theme.base05
                                    font.family: Theme.fontFamilyFallback
                                    font.pixelSize: Theme.fontSize + 6
                                }
                            }

                            Column {
                                width: parent.width - 48 - 10 - (3 * 30 + 2 * 4) - 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text {
                                    width: parent.width
                                    text: Player.title || "Nothing playing"
                                    color: Theme.base05
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 1
                                    font.weight: Theme.fontWeight
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: Player.artist
                                    color: Theme.base05
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 3
                                    elide: Text.ElideRight
                                    visible: text.length > 0
                                }
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                Repeater {
                                    model: [
                                        { icon: "󰒮", act: "prev" },
                                        { icon: Player.isPlaying ? "󰏤" : "󰐊", act: "toggle" },
                                        { icon: "󰒭", act: "next" }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: 30; height: 30; radius: 15
                                        color: mh.hovered ? Theme.base02 : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.icon
                                            color: Theme.base05
                                            font.family: Theme.fontFamilyFallback
                                            font.pixelSize: Theme.fontSize + (modelData.act === "toggle" ? 3 : 1)
                                        }
                                        HoverHandler { id: mh }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (modelData.act === "prev") Player.previous();
                                                else if (modelData.act === "next") Player.next();
                                                else Player.playPause();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ---- seek bar: position | track | length ----
                        Row {
                            width: parent.width
                            height: 14
                            spacing: 6

                            Text {
                                width: 32; height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                text: Player.fmtTime(seek.dragging ? seek.dragFrac * Player.length : Player.position)
                                color: Theme.base04
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 5
                                font.features: ({ "tnum": 1 })
                            }

                            Item {
                                id: seek
                                width: parent.width - 2 * 32 - 2 * 6
                                height: parent.height
                                property bool dragging: false
                                property real dragFrac: 0
                                readonly property real frac: dragging ? dragFrac : Player.progress

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width; height: 4; radius: 2
                                    color: Theme.base02
                                    Rectangle {
                                        height: parent.height; radius: 2
                                        width: Math.round(parent.width * seek.frac)
                                        color: Theme.base0D
                                    }
                                }
                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    color: Theme.base0D
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.round((parent.width - width) * seek.frac)
                                    visible: Player.canSeek
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: Player.canSeek
                                    function pick(mx) { seek.dragFrac = Math.max(0, Math.min(1, mx / seek.width)); }
                                    onPressed: mouse => { seek.dragging = true; pick(mouse.x); }
                                    onPositionChanged: mouse => { if (seek.dragging) pick(mouse.x); }
                                    onReleased: { Player.seek(seek.dragFrac); seek.dragging = false; }
                                }
                            }

                            Text {
                                width: 32; height: parent.height
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                text: Player.fmtTime(Player.length)
                                color: Theme.base04
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 5
                                font.features: ({ "tnum": 1 })
                            }
                        }
                    }
                }

                CtlSlider {
                    icon: win.muted || win.volume === 0 ? "󰖁" : (win.volume >= 50 ? "󰕾" : "󰖀")
                    value: win.volume
                    accent: Theme.base0D
                    badgeActive: win.muted
                    onMoved: v => win.setVolume(v)
                    onBadgeClicked: if (win.sink && win.sink.audio) win.sink.audio.muted = !win.sink.audio.muted
                }
                CtlSlider {
                    icon: Brightness.icon
                    value: Brightness.percent
                    accent: Theme.base0E
                    onMoved: v => Brightness.set(v)
                    onBadgeClicked: {}
                }

                // ---- audio output switcher (collapsible) ----
                Column {
                    width: parent.width
                    spacing: 6

                    Rectangle {
                        width: parent.width
                        height: 38
                        radius: 10
                        color: outHdr.hovered ? Theme.base02 : Theme.base01
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: chevron.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰓃"
                                color: Theme.base0D
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: Theme.fontSize + 2
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 34
                                text: win.nodeName(win.sink)
                                color: Theme.base05
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                elide: Text.ElideRight
                            }
                        }
                        Text {
                            id: chevron
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: win.audioExpanded ? "󰅃" : "󰅀"
                            color: Theme.base04
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize
                        }
                        HoverHandler { id: outHdr }
                        MouseArea { anchors.fill: parent; onClicked: win.audioExpanded = !win.audioExpanded }
                    }

                    Column {
                        width: parent.width
                        spacing: 4
                        visible: win.audioExpanded
                        Repeater {
                            model: win.sinks
                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width
                                height: 32
                                radius: 8
                                readonly property bool isDefault: modelData === win.sink
                                color: isDefault ? Theme.base02 : (devHover.hovered ? Theme.base01 : "transparent")
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 34
                                    anchors.right: parent.right
                                    anchors.rightMargin: 30
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: win.nodeName(modelData)
                                    color: Theme.base05
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 3
                                    elide: Text.ElideRight
                                }
                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: parent.isDefault ? "󰄬" : ""
                                    color: Theme.base0B
                                    font.family: Theme.fontFamilyFallback
                                    font.pixelSize: Theme.fontSize - 1
                                }
                                HoverHandler { id: devHover }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Pipewire.preferredDefaultAudioSink = modelData;
                                        win.audioExpanded = false;
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 10
                    Tile {
                        icon: Network.icon
                        label: Network.connected ? Network.ssid : "Wi-Fi"
                        accent: Theme.base0B
                        on: Network.radioOn
                        onToggled: Network.setRadio(!Network.radioOn)
                        onOpened: Globals.toggleWifi()
                    }
                    Tile {
                        icon: Bluetooth.icon
                        label: Bluetooth.anyConnected ? Bluetooth.connectedName : "Bluetooth"
                        accent: Theme.base0D
                        on: Bluetooth.powered
                        onToggled: Bluetooth.setPowered(!Bluetooth.powered)
                        onOpened: Globals.toggleBluetooth()
                    }
                    Tile {
                        icon: "󰃝"
                        label: "Night Light"
                        accent: Theme.base09
                        on: Nightlight.active
                        onToggled: Nightlight.active ? Nightlight.disable() : Nightlight.enable()
                        onOpened: Globals.toggleNightlight()
                    }
                }

                Row {
                    width: parent.width
                    spacing: 10
                    Tile {
                        icon: Notifications.doNotDisturb ? "󰂛" : "󰂚"
                        label: "Do Not Disturb"
                        accent: Theme.base08
                        on: Notifications.doNotDisturb
                        onToggled: Notifications.doNotDisturb = !Notifications.doNotDisturb
                        onOpened: Notifications.doNotDisturb = !Notifications.doNotDisturb
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "click toggles · right-click opens details"
                    color: Theme.base03
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 4
                }
            }
        }
    }
}
