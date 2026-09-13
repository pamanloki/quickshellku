import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// "About This System" — native info card (inspired by noctalia/caelestia),
// opened from the Apple menu. Centered, Escape / click-away to close.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.aboutOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:about"

        onVisibleChanged: if (visible) SysInfo.refresh()

        Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: Globals.aboutOpen = false }
        MouseArea { anchors.fill: parent; onClicked: Globals.aboutOpen = false }

        // info row
        component Row2: Row {
            property string k: ""
            property string v: ""
            width: parent.width
            spacing: 10
            visible: v.length > 0
            Text {
                text: k
                width: 96
                horizontalAlignment: Text.AlignRight
                color: Theme.base04
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
            }
            Text {
                text: v
                width: parent.width - 106
                color: Theme.base05
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                font.weight: Theme.fontWeight
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: box
            width: 400
            height: col.implicitHeight + 40
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -30
            radius: 20
            color: Theme.base00
            border.width: 1
            border.color: Theme.base02

            opacity: win.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEffects } }
            scale: win.visible ? 1 : 0.94
            Behavior on scale { NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpatial } }

            MouseArea { anchors.fill: parent }

            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 6

                // logo
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: ""    // nf-linux-void
                    color: Theme.accent
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: 64
                    bottomPadding: 4
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SysInfo.osPretty
                    color: Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 6
                    font.weight: Theme.fontWeight
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SysInfo.user + "@" + SysInfo.hostname
                    color: Theme.base04
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    bottomPadding: 10
                }

                // info card
                Rectangle {
                    width: parent.width
                    height: info.implicitHeight + 24
                    radius: 14
                    color: Theme.base01
                    Column {
                        id: info
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 14
                        spacing: 7
                        Row2 { k: "Kernel";     v: SysInfo.kernel }
                        Row2 { k: "Desktop";    v: SysInfo.desktop }
                        Row2 { k: "Processor";  v: SysInfo.cpu }
                        Row2 {
                            k: "Memory"
                            v: SystemStats.memTotalGiB > 0
                                ? (SystemStats.memUsedGiB.toFixed(1) + " / " + SystemStats.memTotalGiB.toFixed(1) + " GiB")
                                : ""
                        }
                        Row2 { k: "Disk";       v: SystemStats.diskFree !== "--" ? SystemStats.diskFree + " free" : "" }
                        Row2 { k: "Shell";      v: SysInfo.shell }
                        Row2 { k: "Uptime";     v: SysInfo.uptime }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "quickshellku"
                    color: Theme.base03
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 4
                    topPadding: 8
                }
            }
        }
    }
}
