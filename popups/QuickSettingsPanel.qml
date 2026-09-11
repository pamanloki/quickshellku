import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "root:/services"

// Quick Settings, using the iOS 26/27 Control Centre *layout* (a floating card
// with a 2x2 round connectivity cluster, tall vertical brightness/volume
// sliders, a now-playing tile with a scrubber, and an output picker) — but with
// solid theme colours, no translucent "liquid glass" and no blur.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.quickSettingsOpen || slide.y < box.height
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
                if (n && n.isSink && !n.isStream)
                    out.push(n);
            }
            return out;
        }
        property bool audioExpanded: false
        function nodeName(n) {
            return n ? (n.description || n.nickname || n.name || "Unknown") : "None";
        }
        function setVolume(v) {
            if (!sink || !sink.audio) return;
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, v / 100));
        }

        PwObjectTracker { objects: win.sink ? [win.sink] : [] }
        PwObjectTracker { objects: win.sinks }

        onVisibleChanged: if (visible) { audioExpanded = false; Network.refresh(); Bluetooth.refresh(); Nightlight.refresh(); }

        // ---- palette (solid theme colours — iOS layout, no glass) ----
        readonly property color modBg: Theme.base01
        readonly property color slotBg: Theme.base02
        readonly property color hairline: "transparent"

        // ================= components =================

        // Round connectivity toggle (iOS control-centre style).
        component RoundToggle: Rectangle {
            id: rt
            property string icon: ""
            property color accent: Theme.base0D
            property bool on: false
            property real size: 58
            signal toggled()
            signal opened()
            implicitWidth: size; implicitHeight: size
            radius: size / 2
            color: on ? (rtMA.containsMouse ? Qt.lighter(accent, 1.18) : accent)
                      : (rtMA.containsMouse ? Theme.base03 : win.slotBg)
            Behavior on color { ColorAnimation { duration: 120 } }
            border.width: 1
            border.color: on ? "transparent" : win.hairline
            scale: rtMA.containsMouse ? 1.06 : 1
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            Text {
                anchors.centerIn: parent
                text: rt.icon
                color: rt.on ? Theme.base00 : Theme.base05
                font.family: Theme.fontFamilyFallback
                font.pixelSize: Theme.fontSize + 6
            }
            MouseArea {
                id: rtMA
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => mouse.button === Qt.RightButton ? rt.opened() : rt.toggled()
            }
        }

        // round toggle + caption (shows connected SSID / device name)
        component ConnCell: Column {
            property alias icon: tgl.icon
            property alias accent: tgl.accent
            property alias on: tgl.on
            property string caption: ""
            signal toggled()
            signal opened()
            width: 74
            spacing: 4
            RoundToggle {
                id: tgl
                anchors.horizontalCenter: parent.horizontalCenter
                size: 52
                onToggled: parent.toggled()
                onOpened: parent.opened()
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: parent.caption
                color: Theme.base04
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 6
                elide: Text.ElideRight
            }
        }

        // Tall vertical slider (brightness / volume).
        component VSlider: Item {
            id: vs
            property string icon: ""
            property int value: 0
            property color accent: Theme.base05
            property bool badgeMuted: false
            signal moved(int v)
            property bool dragging: false
            property int dragValue: 0
            readonly property int shown: dragging ? dragValue : value

            Rectangle {
                id: vtrack
                anchors.fill: parent
                radius: 18
                color: win.slotBg
                border.width: 1
                border.color: win.hairline

                Rectangle {   // fill grows from the bottom, rounded like the track
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    radius: vtrack.radius
                    height: Math.max(vs.shown > 0 ? radius : 0,
                        Math.round(parent.height * Math.max(0, Math.min(100, vs.shown)) / 100))
                    color: vs.badgeMuted ? Theme.base08 : vs.accent
                    Behavior on height { enabled: !vs.dragging; NumberAnimation { duration: 90 } }
                }

                Text {   // icon pinned near the bottom, iOS-style
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    text: vs.icon
                    color: vs.shown > 14 ? Theme.base00 : Theme.base05
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: Theme.fontSize + 6
                }
            }

            MouseArea {
                anchors.fill: parent
                function pick(my) {
                    vs.dragValue = Math.round(Math.max(0, Math.min(1, 1 - my / height)) * 100);
                    vs.moved(vs.dragValue);
                }
                onPressed: mouse => { vs.dragging = true; pick(mouse.y); }
                onPositionChanged: mouse => { if (vs.dragging) pick(mouse.y); }
                onReleased: vs.dragging = false
            }
        }

        MouseArea { anchors.fill: parent; onClicked: Globals.quickSettingsOpen = false }

        Item {
            id: box
            transform: Translate {
                id: slide
                y: Globals.quickSettingsOpen ? 0 : box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }

            width: 372
            height: contentCol.implicitHeight + 30
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 8
            anchors.bottomMargin: 0

            // rounded top, open bottom → merges into the bar like the other panels
            IslandBg { anchors.fill: parent; radius: 22 }
            MouseArea { anchors.fill: parent }

            Column {
                id: contentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 14

                // ---- header: date + wallpaper/theme ----
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
                            font.pixelSize: Theme.fontSize + 3
                            font.weight: Theme.fontWeight
                        }
                        Text {
                            text: Qt.formatDate(Time.now, "d MMMM yyyy")
                            color: Theme.base04
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                        }
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: wallH.hovered ? win.slotBg : win.modBg
                            border.width: 1; border.color: win.hairline
                            Text { anchors.centerIn: parent; text: "󰸉"; color: Theme.base0C
                                font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize + 4 }
                            HoverHandler { id: wallH }
                            MouseArea { anchors.fill: parent; onClicked: Globals.toggleWallpaper() }
                        }
                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: themeH.hovered ? win.slotBg : win.modBg
                            border.width: 1; border.color: win.hairline
                            Text { anchors.centerIn: parent; text: "󰸌"; color: Theme.base0E
                                font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize + 4 }
                            HoverHandler { id: themeH }
                            MouseArea { anchors.fill: parent; onClicked: Globals.toggleTheme() }
                        }
                    }
                }

                // ---- connectivity cluster  +  vertical sliders ----
                Row {
                    width: parent.width
                    spacing: 14
                    readonly property real colW: (width - 14) / 2
                    readonly property real blockH: 168

                    // 2x2 round toggles, each with a caption (connected SSID /
                    // device name shows here)
                    Rectangle {
                        width: parent.colW
                        height: parent.blockH
                        radius: 24
                        color: win.modBg
                        border.width: 1; border.color: win.hairline

                        Grid {
                            anchors.centerIn: parent
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 8
                            ConnCell {
                                icon: Network.icon
                                accent: Theme.base0B
                                on: Network.radioOn
                                caption: Network.connected ? Network.ssid : (Network.radioOn ? "Wi-Fi" : "Off")
                                onToggled: Network.setRadio(!Network.radioOn)
                                onOpened: Globals.toggleWifi()
                            }
                            ConnCell {
                                icon: Bluetooth.icon
                                accent: Theme.base0D
                                on: Bluetooth.powered
                                caption: Bluetooth.anyConnected ? Bluetooth.connectedName : (Bluetooth.powered ? "Bluetooth" : "Off")
                                onToggled: Bluetooth.setPowered(!Bluetooth.powered)
                                onOpened: Globals.toggleBluetooth()
                            }
                            ConnCell {
                                icon: "󰃝"
                                accent: Theme.base09
                                on: Nightlight.active
                                caption: Nightlight.active ? "On" : "Off"
                                onToggled: Nightlight.active ? Nightlight.disable() : Nightlight.enable()
                                onOpened: Globals.toggleNightlight()
                            }
                            ConnCell {
                                icon: Notifications.doNotDisturb ? "󰂛" : "󰂚"
                                accent: Theme.base08
                                on: Notifications.doNotDisturb
                                caption: Notifications.doNotDisturb ? "On" : "Off"
                                onToggled: Notifications.doNotDisturb = !Notifications.doNotDisturb
                                onOpened: Notifications.doNotDisturb = !Notifications.doNotDisturb
                            }
                        }
                    }

                    // brightness + volume vertical sliders
                    Row {
                        width: parent.colW
                        height: parent.blockH
                        spacing: 14
                        VSlider {
                            width: (parent.width - 14) / 2
                            height: parent.height
                            icon: Brightness.icon
                            value: Brightness.percent
                            accent: Theme.base0E
                            onMoved: v => Brightness.set(v)
                        }
                        VSlider {
                            width: (parent.width - 14) / 2
                            height: parent.height
                            icon: win.muted || win.volume === 0 ? "󰖁" : (win.volume >= 50 ? "󰕾" : "󰖀")
                            value: win.volume
                            accent: Theme.base0D
                            badgeMuted: win.muted
                            onMoved: v => win.setVolume(v)
                        }
                    }
                }

                // ---- now playing ----
                Rectangle {
                    width: parent.width
                    height: 92
                    radius: 22
                    color: win.modBg
                    border.width: 1; border.color: win.hairline
                    visible: Player.hasPlayer

                    Timer {
                        interval: 1000
                        running: win.visible && Player.isPlaying
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: Player.refreshPosition()
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Row {
                            width: parent.width
                            height: 46
                            spacing: 10
                            Rectangle {
                                width: 46; height: 46; radius: 10
                                anchors.verticalCenter: parent.verticalCenter
                                color: win.slotBg
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
                                width: parent.width - 46 - 10 - (3 * 30 + 2 * 4) - 10
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
                                    color: Theme.base04
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
                                        color: mh.hovered ? win.slotBg : "transparent"
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
                                    color: win.slotBg
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

                // ---- audio output switcher (collapsible) ----
                Column {
                    width: parent.width
                    spacing: 6

                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: 14
                        color: outHdr.hovered ? win.slotBg : win.modBg
                        border.width: 1; border.color: win.hairline
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
                                height: 34
                                radius: 12
                                readonly property bool isDefault: modelData === win.sink
                                color: isDefault ? win.slotBg : (devHover.hovered ? win.modBg : "transparent")
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    anchors.right: parent.right
                                    anchors.rightMargin: 34
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: win.nodeName(modelData)
                                    color: Theme.base05
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 3
                                    elide: Text.ElideRight
                                }
                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
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
            }
        }
    }
}
