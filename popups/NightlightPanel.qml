import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Native night light panel (wlsunset), styled like the Wi-Fi panel.
// Toggle, warmer/cooler, a temperature slider, and auto/manual schedule.
// Actions delegate to your nightlight-fuzzel script.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.nightlightOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:nightlight"

        // live preview of the slider value while dragging
        property int previewTemp: Nightlight.nightTemp
        property bool dragging: false

        onVisibleChanged: {
            if (visible) {
                Nightlight.refresh();
                previewTemp = Nightlight.nightTemp;
            }
        }
        Connections {
            target: Nightlight
            function onNightTempChanged() {
                if (!win.dragging)
                    win.previewTemp = Nightlight.nightTemp;
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Globals.nightlightOpen = false
        }

        Item {
            id: box
            opacity: win.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEffects } }
            transform: Translate {
                y: win.visible ? 0 : 28
                Behavior on y { NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpatial } }
            }
            width: 340
            height: 300
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 8
            anchors.bottomMargin: 0
            IslandBg { anchors.fill: parent; radius: 8 }

            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // Header + on/off toggle
                Row {
                    width: parent.width
                    Text {
                        text: "󰛨  Night Light"
                        color: Theme.base05
                        font.family: Theme.fontFamilyFallback
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: Theme.fontWeight
                        width: parent.width - 60
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: 52; height: 26; radius: 13
                        color: Nightlight.active ? Theme.base0B : Theme.base03
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            width: 20; height: 20; radius: 10; color: Theme.base00
                            anchors.verticalCenter: parent.verticalCenter
                            x: Nightlight.active ? parent.width - width - 3 : 3
                            Behavior on x { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Nightlight.active ? Nightlight.disable() : Nightlight.enable()
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: Nightlight.active
                        ? ("On — night " + win.previewTemp + "K")
                        : ("Off — neutral " + Nightlight.dayTemp + "K")
                    color: Nightlight.active ? Theme.base0B : Theme.base03
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                }

                // Temperature slider
                Column {
                    width: parent.width
                    spacing: 6
                    Row {
                        width: parent.width
                        Text {
                            text: "Temperature"
                            color: Theme.base05
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            width: parent.width - 80
                        }
                        Text {
                            text: win.previewTemp + "K"
                            color: Theme.base0E
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            font.weight: Theme.fontWeight
                            font.features: ({ "tnum": 1 })
                            horizontalAlignment: Text.AlignRight
                            width: 80
                        }
                    }
                    Item {
                        id: slider
                        width: parent.width
                        height: 22
                        readonly property int span: Nightlight.maxTemp - Nightlight.minTemp
                        readonly property real ratio: (win.previewTemp - Nightlight.minTemp) / span

                        Rectangle { // track
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 6
                            radius: 3
                            color: Theme.base02
                            Rectangle {
                                width: Math.round(parent.width * slider.ratio)
                                height: parent.height
                                radius: 3
                                color: Theme.base0E
                            }
                        }
                        Rectangle { // handle
                            width: 16; height: 16; radius: 8
                            color: Theme.base0E
                            border.color: Theme.base00
                            border.width: 2
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.round((parent.width - width) * slider.ratio)
                        }

                        MouseArea {
                            anchors.fill: parent
                            function pick(mx) {
                                const r = Math.max(0, Math.min(1, mx / slider.width));
                                let k = Nightlight.minTemp + r * slider.span;
                                // snap to 100K steps
                                k = Math.round(k / 100) * 100;
                                win.previewTemp = k;
                            }
                            onPressed: mouse => { win.dragging = true; pick(mouse.x); }
                            onPositionChanged: mouse => { if (win.dragging) pick(mouse.x); }
                            onReleased: {
                                win.dragging = false;
                                Nightlight.setTemp(win.previewTemp);
                            }
                        }
                    }
                }

                // Warmer / Cooler
                Row {
                    width: parent.width
                    spacing: 8
                    Rectangle {
                        width: (parent.width - 8) / 2; height: 32; radius: 4
                        color: Theme.base02
                        Text {
                            anchors.centerIn: parent
                            text: "󰈸  Warmer"
                            color: Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize - 2
                        }
                        MouseArea { anchors.fill: parent; onClicked: Nightlight.warmer() }
                    }
                    Rectangle {
                        width: (parent.width - 8) / 2; height: 32; radius: 4
                        color: Theme.base02
                        Text {
                            anchors.centerIn: parent
                            text: "󰜗  Cooler"
                            color: Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize - 2
                        }
                        MouseArea { anchors.fill: parent; onClicked: Nightlight.cooler() }
                    }
                }

                // Auto / Manual schedule
                Row {
                    width: parent.width
                    spacing: 8
                    Rectangle {
                        width: (parent.width - 8) / 2; height: 32; radius: 4
                        color: Theme.base01
                        Text {
                            anchors.centerIn: parent
                            text: "󰃭  Auto"
                            color: Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize - 2
                        }
                        MouseArea { anchors.fill: parent; onClicked: Nightlight.scheduleAuto() }
                    }
                    Rectangle {
                        width: (parent.width - 8) / 2; height: 32; radius: 4
                        color: Theme.base01
                        Text {
                            anchors.centerIn: parent
                            text: "󰃰  Manual"
                            color: Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize - 2
                        }
                        MouseArea { anchors.fill: parent; onClicked: Nightlight.scheduleManual() }
                    }
                }
            }
        }
    }
}
