import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "root:/services"

// Unified on-screen display for volume + brightness. It watches the Pipewire
// sink and the Brightness service and pops up automatically on any change
// (mouse scroll, keyboard keys, external tools), so there's a single OSD.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { bottom: true }
        margins.bottom: Theme.barHeight + 70
        implicitWidth: 280
        implicitHeight: 58
        color: "transparent"
        visible: Globals.osdVisible
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:osd"

        // ---- watch volume ----
        readonly property var sink: Pipewire.defaultAudioSink
        readonly property int vol: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
        readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
        property bool ready: false

        PwObjectTracker { objects: win.sink ? [win.sink] : [] }

        onVolChanged: if (ready) Globals.showOsd("volume", vol, muted)
        onMutedChanged: if (ready) Globals.showOsd("volume", vol, muted)

        Connections {
            target: Brightness
            function onPercentChanged() {
                if (win.ready) Globals.showOsd("brightness", Brightness.percent, false);
            }
        }

        // don't pop the OSD for the initial values at startup
        Timer { running: true; interval: 1200; onTriggered: win.ready = true }

        readonly property bool isVol: Globals.osdKind === "volume"
        readonly property string osdIcon: isVol
            ? (Globals.osdMuted || Globals.osdValue === 0 ? "󰖁" : Globals.osdValue >= 50 ? "󰕾" : "󰖀")
            : (Globals.osdValue >= 66 ? "󰃠" : Globals.osdValue >= 33 ? "󰃟" : "󰃞")
        readonly property color osdColor: isVol ? Theme.base0D : Theme.base0E

        Rectangle {
            anchors.fill: parent
            color: Theme.base00
            border.color: Theme.base02
            border.width: 2
            radius: 14

            Row {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.osdIcon
                    color: win.osdColor
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: 26
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 100
                    height: 8
                    radius: 4
                    color: Theme.base02
                    Rectangle {
                        height: parent.height
                        radius: 4
                        width: parent.width * Math.max(0, Math.min(100, Globals.osdValue)) / 100
                        color: win.osdColor
                        Behavior on width { NumberAnimation { duration: 90 } }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    horizontalAlignment: Text.AlignRight
                    text: (Globals.osdMuted && win.isVol) ? "×" : (Globals.osdValue + "%")
                    color: Theme.base05
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }
}
