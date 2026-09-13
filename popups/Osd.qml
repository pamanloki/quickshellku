import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "root:/services"

// macOS-style on-screen display for volume + brightness: a centred rounded
// square with a big glyph and the classic 16-segment level bar. Watches the
// Pipewire sink and the Brightness service and pops up automatically on change.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.osdVisible || card.opacity > 0.01
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
        readonly property bool isMuted: Globals.osdMuted && isVol
        readonly property string osdIcon: isVol
            ? (isMuted || Globals.osdValue === 0 ? "󰖁" : Globals.osdValue >= 50 ? "󰕾" : "󰖀")
            : "󰃟"
        // 16 segments, classic macOS HUD
        readonly property int filled: Math.round(Math.max(0, Math.min(100, Globals.osdValue)) / 100 * 16)

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: 190
            height: 190
            radius: 26
            color: Theme.base00
            border.color: Theme.base02
            border.width: 1

            opacity: Globals.osdVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.OutCubic } }
            scale: Globals.osdVisible ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.OutCubic } }

            // big glyph
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 34
                text: win.osdIcon
                color: win.isMuted ? Theme.accent : Theme.base05
                font.family: Theme.fontFamilyFallback
                font.pixelSize: 84
            }

            // 16-segment level bar
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 26
                spacing: 3
                Repeater {
                    model: 16
                    delegate: Rectangle {
                        required property int index
                        width: 7
                        height: 12
                        radius: 2
                        color: index < win.filled
                            ? (win.isVol ? Theme.accent : Theme.accent)
                            : Theme.base02
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }
                }
            }
        }
    }
}
