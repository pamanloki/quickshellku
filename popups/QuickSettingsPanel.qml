import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "root:/services"

// Quick Settings, iOS 26/27 Control Centre style: a bottom panel you swipe
// up/down between two pages — page 1 the controls, page 2 a full media player —
// with a little page indicator. Solid theme colours, no glass/blur.
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

        onVisibleChanged: if (visible) {
            audioExpanded = false;
            pager.contentY = 0; pager.page = 0;
            Network.refresh(); Bluetooth.refresh(); Nightlight.refresh();
        }

        // ---- palette ----
        readonly property color modBg: Theme.base01
        readonly property color slotBg: Theme.base02
        readonly property color hairline: "transparent"

        // ================= components =================

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

        // Horizontal slider (macOS Control Centre style): rounded track, fill
        // from the left, icon inside on the left.
        component HSlider: Item {
            id: hs
            property string icon: ""
            property int value: 0
            property color accent: Theme.base0D
            property bool badgeMuted: false
            signal moved(int v)
            property bool dragging: false
            property int dragValue: 0
            readonly property int shown: dragging ? dragValue : value
            height: 40

            Rectangle {
                id: htrack
                anchors.fill: parent
                radius: 13
                color: win.slotBg

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    radius: htrack.radius
                    width: Math.max(hs.shown > 0 ? 2 * radius : 0,
                        Math.round(parent.width * Math.max(0, Math.min(100, hs.shown)) / 100))
                    color: hs.badgeMuted ? Theme.base08 : hs.accent
                    Behavior on width { enabled: !hs.dragging; NumberAnimation { duration: 90 } }
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 13
                    anchors.verticalCenter: parent.verticalCenter
                    text: hs.icon
                    color: hs.shown > 6 ? Theme.base00 : Theme.base05
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: Theme.fontSize + 4
                }
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true    // don't let the pager steal a slider drag
                function pick(mx) {
                    hs.dragValue = Math.round(Math.max(0, Math.min(1, mx / width)) * 100);
                    hs.moved(hs.dragValue);
                }
                onPressed: mouse => { hs.dragging = true; pick(mouse.x); }
                onPositionChanged: mouse => { if (hs.dragging) pick(mouse.x); }
                onReleased: hs.dragging = false
            }
        }

        MouseArea { anchors.fill: parent; onClicked: Globals.quickSettingsOpen = false }

        Item {
            id: box
            transform: Translate {
                id: slide
                y: Globals.quickSettingsOpen ? 0 : -box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }

            width: 372
            height: 404
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 8
            anchors.topMargin: Theme.menuBarHeight + 6

            Rectangle { anchors.fill: parent; radius: 20; color: Theme.base00; border.width: 1; border.color: Theme.base02 }
            MouseArea { anchors.fill: parent }

            // ---- swipeable pager (page 0 = controls, page 1 = media) ----
            Flickable {
                id: pager
                anchors.fill: parent
                clip: true
                interactive: true
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: height * 2
                property int page: 0
                property real pressY: 0

                function goTo(p) { page = p; snapAnim.to = p * height; snapAnim.restart(); }
                onMovementStarted: pressY = contentY
                onMovementEnded: {
                    const delta = contentY - pressY;    // includes flick momentum
                    if (delta > height * 0.16) goTo(1);
                    else if (delta < -height * 0.16) goTo(0);
                    else goTo(page);                    // snap back
                }
                NumberAnimation { id: snapAnim; target: pager; property: "contentY"; duration: 240; easing.type: Easing.OutCubic }

                Column {
                    width: pager.width

                    // ========================= PAGE 1: controls =========================
                    Item {
                        width: pager.width
                        height: pager.height

                        Column {
                            id: contentCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 18
                            spacing: 14

                            // header: date + wallpaper/theme
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
                                        Text { anchors.centerIn: parent; text: "󰸉"; color: Theme.base0C
                                            font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize + 4 }
                                        HoverHandler { id: wallH }
                                        MouseArea { anchors.fill: parent; onClicked: Globals.toggleWallpaper() }
                                    }
                                    Rectangle {
                                        width: 40; height: 40; radius: 20
                                        color: themeH.hovered ? win.slotBg : win.modBg
                                        Text { anchors.centerIn: parent; text: "󰸌"; color: Theme.base0E
                                            font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize + 4 }
                                        HoverHandler { id: themeH }
                                        MouseArea { anchors.fill: parent; onClicked: Globals.toggleTheme() }
                                    }
                                }
                            }

                            // connectivity card (row of 4 toggles, macOS-style)
                            Rectangle {
                                width: parent.width
                                height: 92
                                radius: 20
                                color: win.modBg
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
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

                            // Display + Sound (horizontal sliders)
                            HSlider {
                                width: parent.width
                                icon: Brightness.icon
                                value: Brightness.percent
                                accent: Theme.base0E
                                onMoved: v => Brightness.set(v)
                            }
                            HSlider {
                                width: parent.width
                                icon: win.muted || win.volume === 0 ? "󰖁" : (win.volume >= 50 ? "󰕾" : "󰖀")
                                value: win.volume
                                accent: Theme.base0D
                                badgeMuted: win.muted
                                onMoved: v => win.setVolume(v)
                            }

                            // audio output switcher (collapsible)
                            Column {
                                width: parent.width
                                spacing: 6

                                Rectangle {
                                    width: parent.width
                                    height: 40
                                    radius: 14
                                    color: outHdr.hovered ? win.slotBg : win.modBg
                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.right: chevron.left
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 10
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰓃"; color: Theme.base0D
                                            font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize + 2
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 34
                                            text: win.nodeName(win.sink)
                                            color: Theme.base05
                                            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 2
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Text {
                                        id: chevron
                                        anchors.right: parent.right; anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: win.audioExpanded ? "󰅃" : "󰅀"
                                        color: Theme.base04
                                        font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize
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
                                                anchors.left: parent.left; anchors.leftMargin: 14
                                                anchors.right: parent.right; anchors.rightMargin: 34
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: win.nodeName(modelData)
                                                color: Theme.base05
                                                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 3
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                anchors.right: parent.right; anchors.rightMargin: 12
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: parent.isDefault ? "󰄬" : ""
                                                color: Theme.base0B
                                                font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize - 1
                                            }
                                            HoverHandler { id: devHover }
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: { Pipewire.preferredDefaultAudioSink = modelData; win.audioExpanded = false; }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ========================= PAGE 2: media =========================
                    Item {
                        width: pager.width
                        height: pager.height

                        Timer {
                            interval: 1000
                            running: win.visible && Player.isPlaying && pager.page === 1
                            repeat: true
                            triggeredOnStart: true
                            onTriggered: Player.refreshPosition()
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 18
                            spacing: 12

                            // big album art
                            Rectangle {
                                width: parent.width
                                height: 168
                                radius: 16
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
                                    text: "󰝚"; color: Theme.base05
                                    font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize + 30
                                }
                            }

                            // title + artist
                            Row {
                                width: parent.width
                                Column {
                                    width: parent.width - 30
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3
                                    Text {
                                        width: parent.width
                                        text: Player.title || "Not Playing"
                                        color: Theme.base05
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize + 4
                                        font.weight: Theme.fontWeight
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        text: Player.artist
                                        color: Theme.base04
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize - 1
                                        elide: Text.ElideRight
                                        visible: text.length > 0
                                    }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰎈"
                                    color: Theme.base0E
                                    font.family: Theme.fontFamilyFallback
                                    font.pixelSize: Theme.fontSize + 4
                                }
                            }

                            // scrubber
                            Row {
                                width: parent.width
                                height: 16
                                spacing: 8
                                Text {
                                    width: 36; height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    text: Player.fmtTime(mseek.dragging ? mseek.dragFrac * Player.length : Player.position)
                                    color: Theme.base04
                                    font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 4
                                    font.features: ({ "tnum": 1 })
                                }
                                Item {
                                    id: mseek
                                    width: parent.width - 2 * 36 - 2 * 8
                                    height: parent.height
                                    property bool dragging: false
                                    property real dragFrac: 0
                                    readonly property real frac: dragging ? dragFrac : Player.progress
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width; height: 6; radius: 3
                                        color: win.slotBg
                                        Rectangle {
                                            height: parent.height; radius: 3
                                            width: Math.round(parent.width * mseek.frac)
                                            color: Theme.base0D
                                        }
                                    }
                                    Rectangle {
                                        width: 12; height: 12; radius: 6
                                        color: Theme.base0D
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.round((parent.width - width) * mseek.frac)
                                        visible: Player.canSeek
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        preventStealing: true
                                        enabled: Player.canSeek
                                        function pick(mx) { mseek.dragFrac = Math.max(0, Math.min(1, mx / mseek.width)); }
                                        onPressed: mouse => { mseek.dragging = true; pick(mouse.x); }
                                        onPositionChanged: mouse => { if (mseek.dragging) pick(mouse.x); }
                                        onReleased: { Player.seek(mseek.dragFrac); mseek.dragging = false; }
                                    }
                                }
                                Text {
                                    width: 36; height: parent.height
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                    text: Player.fmtTime(Player.length)
                                    color: Theme.base04
                                    font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 4
                                    font.features: ({ "tnum": 1 })
                                }
                            }

                            // transport controls
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 26
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰒮"; color: Theme.base05
                                    font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize + 12
                                    MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: Player.previous() }
                                }
                                Rectangle {
                                    width: 60; height: 60; radius: 30
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: playH.hovered ? Qt.lighter(Theme.base0D, 1.15) : Theme.base0D
                                    Text {
                                        anchors.centerIn: parent
                                        text: Player.isPlaying ? "󰏤" : "󰐊"
                                        color: Theme.base00
                                        font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize + 12
                                    }
                                    HoverHandler { id: playH }
                                    MouseArea { anchors.fill: parent; onClicked: Player.playPause() }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰒭"; color: Theme.base05
                                    font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize + 12
                                    MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: Player.next() }
                                }
                            }

                            // volume
                            Row {
                                width: parent.width
                                spacing: 12
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: win.muted || win.volume === 0 ? "󰖁" : (win.volume >= 50 ? "󰕾" : "󰖀")
                                    color: Theme.base05
                                    font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize + 4
                                }
                                Item {
                                    width: parent.width - 34
                                    height: 22
                                    anchors.verticalCenter: parent.verticalCenter
                                    property bool dragging: false
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width; height: 6; radius: 3
                                        color: win.slotBg
                                        Rectangle {
                                            height: parent.height; radius: 3
                                            width: Math.round(parent.width * Math.max(0, Math.min(100, win.volume)) / 100)
                                            color: Theme.base0D
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        preventStealing: true
                                        function pick(mx) { win.setVolume(Math.round(Math.max(0, Math.min(1, mx / width)) * 100)); }
                                        onPressed: mouse => pick(mouse.x)
                                        onPositionChanged: mouse => { if (pressed) pick(mouse.x); }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- page indicator dots ----
            Column {
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7
                Repeater {
                    model: 2
                    delegate: Rectangle {
                        required property int index
                        width: 7; height: 7; radius: 4
                        color: pager.page === index ? Theme.base05 : Theme.base03
                        opacity: pager.page === index ? 1 : 0.6
                        Behavior on color { ColorAnimation { duration: 120 } }
                        MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: pager.goTo(index) }
                    }
                }
            }
        }
    }
}
