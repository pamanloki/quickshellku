import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// macOS-style low-battery alert. Pops a centred card when the Battery service
// reports crossing 20% / 10% while discharging; auto-dismisses after a few
// seconds, or on click.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: shown || card.opacity > 0.01
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:batteryalert"

        property bool shown: false
        property int level: 20

        Connections {
            target: Battery
            function onLowWarning(l) {
                win.level = l;
                win.shown = true;
                hideTimer.restart();
            }
        }
        Timer { id: hideTimer; interval: 7000; onTriggered: win.shown = false }

        MouseArea { anchors.fill: parent; enabled: win.shown; onClicked: win.shown = false }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Theme.menuBarHeight + 24
            width: row.implicitWidth + 40
            height: 80
            radius: 20
            color: Theme.base00
            border.width: 1
            border.color: win.level <= 10 ? Theme.base08 : Theme.base02

            opacity: win.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.OutCubic } }
            scale: win.shown ? 1 : 0.92
            Behavior on scale { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.OutCubic } }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 14

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 48; height: 48; radius: 12
                    color: win.level <= 10 ? Theme.base08 : Theme.base0A
                    Text {
                        anchors.centerIn: parent
                        text: "󰂃"
                        color: Theme.base00
                        font.family: Theme.fontFamilyFallback
                        font.pixelSize: 26
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Text {
                        text: win.level <= 10 ? "Battery Critically Low" : "Battery Low"
                        color: Theme.base05
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.weight: Theme.fontWeight
                    }
                    Text {
                        text: Battery.percent + "% remaining"
                            + (Battery.timeText.length > 0
                               ? " · " + Battery.timeText.replace(" remaining", "")
                               : "") + " — plug in your charger"
                        color: Theme.base04
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }
        }
    }
}
