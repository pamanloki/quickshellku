import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Native Bluetooth panel over bluez. Toggle power, scan, connect/disconnect.
// "Manage in bluetui" is always available.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.bluetoothOpen || slide.y > -box.height
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:bluetooth"

        onVisibleChanged: if (visible) Bluetooth.refresh()

        MouseArea {
            anchors.fill: parent
            onClicked: Globals.bluetoothOpen = false
        }

        Rectangle {
            id: box
            transform: Translate {
                id: slide
                y: Globals.bluetoothOpen ? 0 : -box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }
            width: 360
            height: 420
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
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header: title + scan + power toggle
                Row {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: "Bluetooth"
                        color: Theme.base05
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: Theme.fontWeight
                        width: parent.width - 96
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {   // scan
                        width: 28; height: 26; radius: 8
                        anchors.verticalCenter: parent.verticalCenter
                        color: btScanMA.containsMouse ? Theme.base02 : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰑐"
                            color: Bluetooth.scanning ? Theme.accent : Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize
                        }
                        MouseArea { id: btScanMA; anchors.fill: parent; hoverEnabled: true; onClicked: Bluetooth.toggleScan() }
                    }
                    Rectangle {   // power toggle
                        width: 52; height: 26; radius: 13
                        color: Bluetooth.powered ? Theme.accent : Theme.base03
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            width: 20; height: 20; radius: 10; color: Theme.base00
                            anchors.verticalCenter: parent.verticalCenter
                            x: Bluetooth.powered ? parent.width - width - 3 : 3
                            Behavior on x { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Bluetooth.setPowered(!Bluetooth.powered)
                        }
                    }
                }

                ListView {
                    id: devList
                    width: parent.width
                    height: parent.height - 80
                    clip: true
                    model: Bluetooth.devices
                    spacing: 4

                    delegate: Rectangle {
                        required property var modelData
                        width: devList.width
                        height: 40
                        color: modelData.connected ? Theme.base02 : (btRowHover.hovered ? Theme.base01 : "transparent")
                        radius: 10
                        HoverHandler { id: btRowHover }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.connected ? "󰂱" : (modelData.paired ? "󰂯" : "󰂰")
                                color: modelData.connected ? Theme.accent : Theme.base05
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: Theme.fontSize
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                color: Theme.base05
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                width: devList.width - 116
                                elide: Text.ElideRight
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.connected ? "󰄬" : ""
                                color: Theme.accent
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: Theme.fontSize - 1
                                visible: modelData.connected
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (modelData.connected)
                                    Bluetooth.disconnect(modelData.mac);
                                else
                                    Bluetooth.connect(modelData.mac);
                            }
                        }
                    }
                }
            }
        }
    }
}
