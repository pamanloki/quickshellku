import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// macOS-style Apple menu: drops from the top-left  logo. Session actions
// delegate to the existing power-fuzzel script.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.appleMenuOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:applemenu"

        function run(item) {
            if (item.act === "about")
                Quickshell.execDetached(["footx", "-e", "-f", "sh", "-c", "nitch; printf '\\nEnter...'; read _"]);
            else if (item.flag)
                Quickshell.execDetached(["power-fuzzel", item.flag]);
            Globals.appleMenuOpen = false;
        }

        Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: Globals.appleMenuOpen = false }
        MouseArea { anchors.fill: parent; onClicked: Globals.appleMenuOpen = false }

        Rectangle {
            id: box
            width: 230
            height: col.implicitHeight + 10
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 6
            anchors.topMargin: 4
            radius: 10
            color: Theme.base01
            border.width: 1
            border.color: Theme.base02

            opacity: win.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEffects } }
            transformOrigin: Item.Top
            scale: win.visible ? 1 : 0.92
            Behavior on scale { NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpatial } }

            MouseArea { anchors.fill: parent }

            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 5
                spacing: 1

                Repeater {
                    model: [
                        { label: "About This System", act: "about" },
                        { sep: true },
                        { label: "Lock Screen", flag: "--lock" },
                        { label: "Sleep", flag: "--suspend" },
                        { sep: true },
                        { label: "Restart…", flag: "--reboot" },
                        { label: "Shut Down…", flag: "--shutdown" },
                        { sep: true },
                        { label: "Log Out", flag: "--logout" }
                    ]
                    delegate: Item {
                        id: mi
                        required property var modelData
                        width: col.width
                        implicitHeight: mi.modelData.sep === true ? 9 : 30

                        Rectangle {   // separator
                            visible: mi.modelData.sep === true
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            height: 1
                            color: Theme.base03
                        }
                        Rectangle {   // item
                            visible: mi.modelData.sep !== true
                            anchors.fill: parent
                            radius: 7
                            color: itemMA.containsMouse ? Theme.base0D : "transparent"
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: mi.modelData.label || ""
                                color: itemMA.containsMouse ? Theme.base00 : Theme.base05
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                            }
                            MouseArea {
                                id: itemMA
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: win.run(mi.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
