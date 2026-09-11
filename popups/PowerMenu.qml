import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Native power menu. Delegates the actual actions to your existing
// `power-fuzzel` script (so privilege escalation / niri logout stay identical),
// just with a nicer native grid instead of the fuzzel list.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.powerOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:power"

        function run(flag) {
            Quickshell.execDetached(["power-fuzzel", flag]);
            Globals.powerOpen = false;
        }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Globals.powerOpen = false
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Globals.powerOpen = false
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 8
            anchors.bottomMargin: Theme.barHeight
            width: grid.width + 32
            height: grid.height + 32
            opacity: win.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            transformOrigin: Item.BottomRight
            scale: win.visible ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
            color: Theme.base00
            border.color: Theme.base02
            border.width: 1
            radius: 16
            
            // square off the bottom so the panel merges flush into the bar
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                color: Theme.base00
            }
            MouseArea { anchors.fill: parent }

            Grid {
                id: grid
                anchors.centerIn: parent
                columns: 3
                spacing: 16

                Repeater {
                    model: [
                        { icon: "󰌾", label: "Lock",      flag: "--lock",      accent: Theme.base0D },
                        { icon: "󰤄", label: "Suspend",   flag: "--suspend",   accent: Theme.base0C },
                        { icon: "󰋊", label: "Hibernate", flag: "--hibernate", accent: Theme.base0A },
                        { icon: "󰗽", label: "Logout",    flag: "--logout",    accent: Theme.base0E },
                        { icon: "󰜉", label: "Reboot",    flag: "--reboot",    accent: Theme.base09 },
                        { icon: "󰐥", label: "Shutdown",  flag: "--shutdown",  accent: Theme.base08 }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: 120
                        height: 100
                        radius: 8
                        color: hover.hovered ? Theme.base02 : Theme.base01

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                color: modelData.accent
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: 34
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: Theme.base05
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                            }
                        }

                        HoverHandler { id: hover }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: win.run(modelData.flag)
                        }
                    }
                }
            }
        }
    }
}
