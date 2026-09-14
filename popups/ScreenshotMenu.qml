import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Screenshot chooser — region/full → clipboard/file. On pick, the menu closes
// and a short delay lets it disappear before grim/slurp capture, so the menu
// never ends up in the shot.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.screenshotOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:screenshot"

        function pick(act) {
            Globals.screenshotOpen = false;
            Screenshot.menuPick(act);
        }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Globals.screenshotOpen = false
        }
        MouseArea { anchors.fill: parent; onClicked: Globals.screenshotOpen = false }

        Item {
            id: box
            opacity: win.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEffects } }
            scale: win.visible ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpatial } }

            width: 300
            height: col.implicitHeight + 24
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -40

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: Theme.base00
                border.width: 2
                border.color: Theme.base02
            }
            MouseArea { anchors.fill: parent }

            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 4

                Text {
                    text: "Screenshot"
                    color: Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 1
                    font.weight: Theme.fontWeight
                    leftPadding: 6
                    bottomPadding: 4
                }

                Repeater {
                    model: [
                        { icon: "󰆞", label: "Region → Clipboard", accent: Theme.accent, act: "rc" },
                        { icon: "󰆞", label: "Region → File",      accent: Theme.accent, act: "rf" },
                        { icon: "󰍹", label: "Full → Clipboard",   accent: Theme.accent, act: "fc" },
                        { icon: "󰍹", label: "Full → File",        accent: Theme.accent, act: "ff" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: col.width
                        height: 44
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
                                width: 32; height: 32; radius: 16
                                color: hover.hovered ? modelData.accent : Theme.base02
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: hover.hovered ? Theme.base00 : modelData.accent
                                    font.family: Theme.fontFamilyFallback
                                    font.pixelSize: Theme.fontSize + 1
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: Theme.base05
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                font.weight: Theme.fontWeight
                            }
                        }

                        HoverHandler { id: hover }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: win.pick(modelData.act)
                        }
                    }
                }
            }
        }
    }
}
