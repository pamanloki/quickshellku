import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// macOS-style Battery menu: level gauge, charge state, power source and time
// estimate. Drops from the top-right below the menu bar.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.batteryOpen || slide.y > -box.height
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:battery"

        readonly property color levelColor: Battery.critical ? Theme.base08
            : Battery.low ? Theme.base0A
            : Battery.charging ? Theme.base0B : Theme.base0D

        MouseArea { anchors.fill: parent; onClicked: Globals.batteryOpen = false }

        // key/value row
        component KV: Item {
            property string k: ""
            property string v: ""
            property color vColor: Theme.base05
            width: parent ? parent.width : 0
            height: 22
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: k
                color: Theme.base04
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: v
                color: vColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                font.weight: Theme.fontWeight
            }
        }

        Rectangle {
            id: box
            transform: Translate {
                id: slide
                y: Globals.batteryOpen ? 0 : -box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }
            width: 300
            height: col.implicitHeight + 32
            x: Globals.panelX < 0
                ? (parent.width - width - 8)
                : Math.max(8, Math.min(parent.width - width - 8, Globals.panelX - width / 2))
            anchors.top: parent.top
            anchors.topMargin: Theme.menuBarHeight + 6
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
                spacing: 12

                Text {
                    text: "Battery"
                    color: Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    font.weight: Theme.fontWeight
                }

                // gauge + percentage
                Row {
                    width: parent.width
                    spacing: 12

                    // battery shape
                    Item {
                        width: 92; height: 40
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            id: shell
                            width: 84; height: 40; radius: 9
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.base03
                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                height: parent.height - 8
                                radius: 5
                                width: Math.max(6, (parent.width - 8) * Math.max(0, Math.min(100, Battery.percent)) / 100)
                                color: win.levelColor
                                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            }
                            // charging bolt
                            Text {
                                anchors.centerIn: parent
                                text: "󰂄"
                                color: Theme.base00
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: Theme.fontSize + 2
                                visible: Battery.charging
                            }
                        }
                        // terminal nub
                        Rectangle {
                            anchors.left: shell.right
                            anchors.verticalCenter: shell.verticalCenter
                            width: 4; height: 14; radius: 2
                            color: Theme.base03
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Battery.present ? (Battery.percent + "%") : "--"
                        color: Theme.base05
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 12
                        font.weight: Theme.fontWeight
                    }
                }

                // divider
                Rectangle { width: parent.width; height: 1; color: Theme.base02 }

                KV { k: "Status"; v: Battery.statusText; vColor: win.levelColor }
                KV { k: "Power Source"; v: Battery.powerSource }
                KV {
                    k: Battery.charging ? "Time to Full" : "Time Remaining"
                    v: Battery.timeText.length > 0
                        ? Battery.timeText.replace(" remaining", "").replace(" to full", "")
                        : "Calculating…"
                    visible: Battery.present && Battery.status !== "Full" && Battery.percent < 100
                }
            }
        }
    }
}
