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
        visible: Globals.bluetoothOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:bluetooth"

        onVisibleChanged: if (visible) Bluetooth.refresh()

        MouseArea {
            anchors.fill: parent
            onClicked: Globals.bluetoothOpen = false
        }

        Item {
            id: box
            opacity: win.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            transformOrigin: Item.BottomRight
            scale: win.visible ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
            width: 360
            height: 420
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 8
            anchors.bottomMargin: 0
            IslandBg { anchors.fill: parent; radius: 8 }

            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Row {
                    width: parent.width
                    Text {
                        text: "󰂯  Bluetooth"
                        color: Theme.base05
                        font.family: Theme.fontFamilyFallback
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: Theme.fontWeight
                        width: parent.width - 60
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: 52; height: 26; radius: 13
                        color: Bluetooth.powered ? Theme.base0B : Theme.base03
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

                Row {
                    width: parent.width
                    spacing: 8
                    Rectangle {
                        width: (parent.width - 8) / 2; height: 30; radius: 4
                        color: Theme.base02
                        Text {
                            anchors.centerIn: parent
                            text: Bluetooth.scanning ? "Scanning…" : "󰑐  Scan"
                            color: Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize - 2
                        }
                        MouseArea { anchors.fill: parent; onClicked: Bluetooth.toggleScan() }
                    }
                    Rectangle {
                        width: (parent.width - 8) / 2; height: 30; radius: 4
                        color: Theme.base02
                        Text {
                            anchors.centerIn: parent
                            text: "  bluetui"
                            color: Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize - 2
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Quickshell.execDetached(["footx", "-f", "-e", "bluetui"]);
                                Globals.bluetoothOpen = false;
                            }
                        }
                    }
                }

                ListView {
                    id: devList
                    width: parent.width
                    height: parent.height - 130
                    clip: true
                    model: Bluetooth.devices
                    spacing: 4

                    delegate: Rectangle {
                        required property var modelData
                        width: devList.width
                        height: 40
                        color: modelData.connected ? Theme.base02 : Theme.base01
                        radius: 4

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.connected ? "󰂱" : (modelData.paired ? "󰂯" : "󰂰")
                                color: modelData.connected ? Theme.base0B : Theme.base05
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: Theme.fontSize
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                color: Theme.base05
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                width: devList.width - 90
                                elide: Text.ElideRight
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
