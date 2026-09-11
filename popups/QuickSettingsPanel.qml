import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "root:/services"

// Combined quick settings: volume + brightness sliders, and WiFi / Bluetooth /
// Night light toggles. Left-click a tile toggles it; right-click opens its
// detailed panel (network list, bluetooth devices, nightlight controls).
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

        // ---- reusable slider ----
        component QSSlider: Item {
            id: sl
            property int value: 0
            property color accent: Theme.base0D
            signal moved(int v)
            height: 22
            property bool dragging: false

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 6; radius: 3; color: Theme.base02
                Rectangle {
                    width: Math.round(parent.width * Math.max(0, Math.min(100, sl.value)) / 100)
                    height: parent.height; radius: 3; color: sl.accent
                }
            }
            Rectangle {
                width: 16; height: 16; radius: 8; color: sl.accent
                border.color: Theme.base00; border.width: 2
                anchors.verticalCenter: parent.verticalCenter
                x: Math.round((parent.width - width) * Math.max(0, Math.min(100, sl.value)) / 100)
            }
            MouseArea {
                anchors.fill: parent
                function pick(mx) {
                    const v = Math.round(Math.max(0, Math.min(1, mx / sl.width)) * 100);
                    sl.value = v; sl.moved(v);
                }
                onPressed: mouse => { sl.dragging = true; pick(mouse.x); }
                onPositionChanged: mouse => { if (sl.dragging) pick(mouse.x); }
                onReleased: sl.dragging = false
            }
        }

        // ---- reusable toggle tile ----
        component Tile: Rectangle {
            id: tile
            property string icon: ""
            property string label: ""
            property bool on: false
            signal toggled()
            signal opened()
            width: (box.width - 28 - 16) / 3
            height: 66
            radius: 10
            color: on ? Theme.base0D : Theme.base02
            Column {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tile.icon
                    color: tile.on ? Theme.base00 : Theme.base05
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: Theme.fontSize + 6
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tile.label
                    color: tile.on ? Theme.base00 : Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 4
                    elide: Text.ElideRight
                    width: tile.width - 8
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
            width: 360
            height: 250
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 8
            anchors.bottomMargin: Theme.barHeight + 6
            color: Theme.base00
            border.color: Theme.base02
            border.width: 2
            radius: 8
            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                // Volume
                Row {
                    width: parent.width
                    spacing: 10
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        text: win.muted || win.volume === 0 ? "󰖁" : (win.volume >= 50 ? "󰕾" : "󰖀")
                        color: Theme.base0D
                        font.family: Theme.fontFamilyFallback
                        font.pixelSize: Theme.fontSize + 4
                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (win.sink && win.sink.audio) win.sink.audio.muted = !win.sink.audio.muted
                        }
                    }
                    QSSlider {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 24 - 10 - 44 - 10
                        value: win.volume
                        accent: Theme.base0D
                        onMoved: v => win.setVolume(v)
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        horizontalAlignment: Text.AlignRight
                        text: win.volume + "%"
                        color: Theme.base05
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        font.features: ({ "tnum": 1 })
                    }
                }

                // Brightness
                Row {
                    width: parent.width
                    spacing: 10
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        text: Brightness.icon
                        color: Theme.base0E
                        font.family: Theme.fontFamilyFallback
                        font.pixelSize: Theme.fontSize + 4
                    }
                    QSSlider {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 24 - 10 - 44 - 10
                        value: Brightness.percent
                        accent: Theme.base0E
                        onMoved: v => Brightness.set(v)
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        horizontalAlignment: Text.AlignRight
                        text: Brightness.percent + "%"
                        color: Theme.base05
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        font.features: ({ "tnum": 1 })
                    }
                }

                // Toggle tiles
                Row {
                    width: parent.width
                    spacing: 8
                    Tile {
                        icon: Network.icon
                        label: Network.connected ? Network.ssid : "Wi-Fi"
                        on: Network.radioOn
                        onToggled: Network.setRadio(!Network.radioOn)
                        onOpened: Globals.toggleWifi()
                    }
                    Tile {
                        icon: Bluetooth.icon
                        label: Bluetooth.anyConnected ? Bluetooth.connectedName : "Bluetooth"
                        on: Bluetooth.powered
                        onToggled: Bluetooth.setPowered(!Bluetooth.powered)
                        onOpened: Globals.toggleBluetooth()
                    }
                    Tile {
                        icon: "󰛨"
                        label: "Night"
                        on: Nightlight.active
                        onToggled: Nightlight.active ? Nightlight.disable() : Nightlight.enable()
                        onOpened: Globals.toggleNightlight()
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "click = toggle · right-click = open details"
                    color: Theme.base03
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 4
                }
            }
        }
    }
}
