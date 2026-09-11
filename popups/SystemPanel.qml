import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// macOS-style system stats: CPU, memory and disk usage with meters. Drops
// from the menu-bar CPU item.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.systemOpen || slide.y > -box.height
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:system"

        MouseArea { anchors.fill: parent; onClicked: Globals.systemOpen = false }

        // one metric: title, value, meter
        component Stat: Column {
            property string label: ""
            property string value: ""
            property real pct: 0
            property color tint: Theme.base0D
            width: parent ? parent.width : 0
            spacing: 6
            Row {
                width: parent.width
                Text {
                    text: label
                    color: Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: Theme.fontWeight
                    width: parent.width - valT.implicitWidth
                }
                Text {
                    id: valT
                    text: value
                    color: Theme.base04
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Rectangle {
                width: parent.width
                height: 8
                radius: 4
                color: Theme.base02
                Rectangle {
                    height: parent.height
                    radius: 4
                    width: Math.max(0, Math.min(1, parent.parent.pct / 100)) * parent.width
                    color: parent.parent.tint
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }
            }
        }

        Rectangle {
            id: box
            transform: Translate {
                id: slide
                y: Globals.systemOpen ? 0 : -box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }
            width: 300
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
                spacing: 16

                Row {
                    width: parent.width
                    Text {
                        text: "System"
                        color: Theme.base05
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: Theme.fontWeight
                        width: parent.width - tempT.implicitWidth
                    }
                    Text {
                        id: tempT
                        visible: SystemStats.tempKnown
                        text: SystemStats.tempC + "°C"
                        color: SystemStats.tempClass === "critical" ? Theme.base08
                            : SystemStats.tempClass === "warm" ? Theme.base0A : Theme.base0B
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        font.weight: Theme.fontWeight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Stat {
                    label: "CPU"
                    value: SystemStats.cpuPercent + "%"
                    pct: SystemStats.cpuPercent
                    tint: SystemStats.cpuPercent >= 85 ? Theme.base08
                        : SystemStats.cpuPercent >= 60 ? Theme.base0A : Theme.base0C
                }
                Stat {
                    label: "Memory"
                    value: SystemStats.memTotalGiB > 0
                        ? (SystemStats.memUsedGiB.toFixed(1) + " / " + SystemStats.memTotalGiB.toFixed(1) + " GiB")
                        : "--"
                    pct: SystemStats.memPercent
                    tint: SystemStats.memPercent >= 85 ? Theme.base08
                        : SystemStats.memPercent >= 60 ? Theme.base0A : Theme.base0D
                }
                Stat {
                    label: "Disk"
                    value: SystemStats.diskUsed !== "--"
                        ? (SystemStats.diskUsed + " / " + SystemStats.diskTotal)
                        : "--"
                    pct: SystemStats.diskPercent
                    tint: SystemStats.diskPercent >= 90 ? Theme.base08
                        : SystemStats.diskPercent >= 75 ? Theme.base0A : Theme.base0E
                }
            }
        }
    }
}
