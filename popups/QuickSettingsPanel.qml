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
        PwObjectTracker { objects: win.sink ? [win.sink] : [] }

        function setVolume(v) {
            if (!sink || !sink.audio) return;
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, v / 100));
        }

        onVisibleChanged: if (visible) { Network.refresh(); Bluetooth.refresh(); Nightlight.refresh(); }

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

        Rectangle {
            id: box
            opacity: win.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            transformOrigin: Item.BottomRight
            scale: win.visible ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
            width: 380
            height: contentCol.implicitHeight + 36
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 8
            anchors.bottomMargin: Theme.barHeight
            color: Theme.base00
            border.color: Theme.base02
            border.width: 1
            radius: 16
            MouseArea { anchors.fill: parent }

            Column {
                id: contentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 16

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
