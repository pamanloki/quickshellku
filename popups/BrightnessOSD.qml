import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Small on-screen display that appears when brightness changes.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { bottom: true }
        margins.bottom: Theme.barHeight + 60
        implicitWidth: 260
        implicitHeight: 56
        color: "transparent"
        visible: Globals.brightnessOsd
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:osd"

        Rectangle {
            anchors.fill: parent
            color: Theme.base00
            border.color: Theme.base02
            border.width: 2
            radius: 12

            Row {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Brightness.icon
                    color: Theme.base0E
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: 24
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 90
                    height: 8
                    radius: 4
                    color: Theme.base02
                    Rectangle {
                        height: parent.height
                        radius: 4
                        width: parent.width * Brightness.percent / 100
                        color: Theme.base0E
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Brightness.percent + "%"
                    color: Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                }
            }
        }
    }
}
