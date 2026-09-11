import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Power menu — a compact vertical list attached to the bar, matching the other
// panels. Actions delegate to the existing power-fuzzel script.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.powerOpen || slide.y > -box.height
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

        Item {
            id: box
            transform: Translate {
                id: slide
                y: Globals.powerOpen ? 0 : -box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }

            width: 260
            height: col.implicitHeight + 24
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 8
            anchors.topMargin: Theme.menuBarHeight + 1

            Rectangle { color: Theme.base00; border.width: 1; border.color: Theme.base02; anchors.fill: parent; radius: 16 }
            MouseArea { anchors.fill: parent }

            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 4

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
                        width: col.width
                        height: 46
                        radius: 10
                        color: hover.hovered ? Theme.base02 : "transparent"
                        Behavior on color { ColorAnimation { duration: 90 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34; height: 34; radius: 17
                                color: hover.hovered ? modelData.accent : Theme.base02
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: hover.hovered ? Theme.base00 : modelData.accent
                                    font.family: Theme.fontFamilyFallback
                                    font.pixelSize: Theme.fontSize + 2
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: Theme.base05
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.weight: Theme.fontWeight
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
