import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "root:/services"

// macOS-style Now Playing popover: album art, title/artist, a scrubber with
// times, and transport controls. Opens from the menu-bar Now Playing item.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.musicOpen || slide.y > -box.height
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:music"

        // ---- audio (for the volume slider) ----
        readonly property var sink: Pipewire.defaultAudioSink
        readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
        readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
        function setVolume(v) {
            if (!sink || !sink.audio) return;
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, v / 100));
        }
        PwObjectTracker { objects: win.sink ? [win.sink] : [] }

        // keep the scrubber live while open
        Timer {
            running: Globals.musicOpen && Player.hasPlayer
            interval: 1000
            repeat: true
            triggeredOnStart: true
            onTriggered: Player.refreshPosition()
        }

        MouseArea { anchors.fill: parent; onClicked: Globals.musicOpen = false }

        Rectangle {
            id: box
            transform: Translate {
                id: slide
                y: Globals.musicOpen ? 0 : -box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }
            width: 320
            height: col.implicitHeight + 32
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
                spacing: 14

                // ---- empty state ----
                Text {
                    visible: !Player.hasPlayer
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 20
                    bottomPadding: 20
                    text: "Nothing Playing"
                    color: Theme.base04
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                // ---- art + title ----
                Row {
                    width: parent.width
                    spacing: 14
                    visible: Player.hasPlayer
                    Rectangle {
                        width: 88; height: 88; radius: 12
                        color: Theme.base02
                        clip: true
                        anchors.verticalCenter: parent.verticalCenter
                        Image {
                            anchors.fill: parent
                            source: Player.artUrl
                            fillMode: Image.PreserveAspectCrop
                            visible: Player.artUrl.length > 0
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "󰎈"
                            color: Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: 34
                            visible: Player.artUrl.length === 0
                        }
                    }
                    Column {
                        width: parent.width - 102
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text {
                            text: Player.title || "Unknown"
                            color: Theme.base05
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 1
                            font.weight: Theme.fontWeight
                            elide: Text.ElideRight
                            width: parent.width
                            maximumLineCount: 2
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            text: Player.artist
                            color: Theme.base04
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            elide: Text.ElideRight
                            width: parent.width
                            visible: text.length > 0
                        }
                    }
                }

                // ---- scrubber ----
                Column {
                    width: parent.width
                    spacing: 4
                    visible: Player.hasPlayer
                    Item {
                        width: parent.width
                        height: 14
                        Rectangle {
                            id: strack
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 5
                            radius: 2.5
                            color: Theme.base02
                            Rectangle {
                                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                                radius: 2.5
                                width: parent.width * Player.progress
                                color: Theme.base0D
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: Player.canSeek
                            onClicked: mouse => Player.seek(Math.max(0, Math.min(1, mouse.x / width)))
                        }
                    }
                    Row {
                        width: parent.width
                        Text {
                            text: Player.fmtTime(Player.position)
                            color: Theme.base04
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 4
                            width: parent.width / 2
                        }
                        Text {
                            text: Player.fmtTime(Player.length)
                            color: Theme.base04
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 4
                            width: parent.width / 2
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // ---- transport ----
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 34
                    topPadding: 2
                    visible: Player.hasPlayer
                    Text {
                        text: "󰒮"; color: Theme.base05
                        font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize + 8
                        MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: Player.previous() }
                    }
                    Text {
                        text: Player.isPlaying ? "󰏤" : "󰐊"; color: Theme.base05
                        font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize + 16
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: Player.playPause() }
                    }
                    Text {
                        text: "󰒭"; color: Theme.base05
                        font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize + 8
                        MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: Player.next() }
                    }
                }

                // ---- volume ----
                Row {
                    width: parent.width
                    spacing: 10
                    visible: Player.hasPlayer
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.muted || win.volume === 0 ? "󰖁" : (win.volume >= 50 ? "󰕾" : "󰖀")
                        color: Theme.base05
                        font.family: Theme.fontFamilyFallback
                        font.pixelSize: Theme.fontSize + 2
                        width: 22
                    }
                    Item {
                        width: parent.width - 32
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            id: vtrack
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 5
                            radius: 2.5
                            color: Theme.base02
                            Rectangle {
                                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                                radius: 2.5
                                width: parent.width * Math.max(0, Math.min(100, win.volume)) / 100
                                color: win.muted ? Theme.base08 : Theme.base0D
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
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
