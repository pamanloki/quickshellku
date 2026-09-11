import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "root:/services"

// Condensed control cluster: volume + wifi + bluetooth status in one pill.
// Click opens the Quick Settings panel; scroll changes volume.
Item {
    id: root
    implicitWidth: Math.round(cap.width)
    implicitHeight: Theme.barHeight

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    function volIcon() {
        if (muted || volume === 0) return "󰖁";
        if (volume >= 50) return "󰕾";
        return "󰖀";
    }
    function setVolume(v) {
        if (!sink || !sink.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    Rectangle {
        id: cap
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight - 2 * Theme.pillVMargin
        radius: Theme.radius
        color: Theme.base03
        width: Math.round(icons.implicitWidth) + 2 * Theme.pillHPad

        Row {
            id: icons
            anchors.centerIn: parent
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.volIcon()
                color: root.muted ? Theme.base08 : Theme.base0D
                font.family: Theme.fontFamilyFallback
                font.pixelSize: Theme.fontSize
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Brightness.icon
                color: Theme.base0E
                font.family: Theme.fontFamilyFallback
                font.pixelSize: Theme.fontSize
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Network.icon
                color: Network.connected ? Theme.base0A : Theme.base08
                font.family: Theme.fontFamilyFallback
                font.pixelSize: Theme.fontSize
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Bluetooth.icon
                color: !Bluetooth.powered ? Theme.base08
                    : (Bluetooth.anyConnected ? Theme.base0B : Theme.base05)
                font.family: Theme.fontFamilyFallback
                font.pixelSize: Theme.fontSize
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: Globals.toggleQuickSettings()
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) root.setVolume((root.volume + 5) / 100);
            else if (wheel.angleDelta.y < 0) root.setVolume((root.volume - 5) / 100);
        }
    }
}
