import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// macOS-style floating thumbnail shown bottom-right after a screenshot is
// saved. Click to open, X to dismiss; auto-hides after a few seconds.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { bottom: true; right: true }
        margins.bottom: Theme.dockIconSize + 54
        margins.right: 14
        implicitWidth: 180
        implicitHeight: 128
        color: "transparent"
        visible: shown || card.opacity > 0.01
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:shotthumb"

        property bool shown: false
        property string path: ""

        Connections {
            target: Screenshot
            function onLastShotChanged() {
                if (Screenshot.lastShot.length === 0) return;
                win.path = Screenshot.lastShot;
                win.shown = true;
                hideTimer.restart();
            }
        }
        Timer { id: hideTimer; interval: 5000; onTriggered: win.shown = false }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 14
            color: Theme.base00
            border.width: 1
            border.color: Theme.base02

            opacity: win.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.OutCubic } }
            transform: Translate {
                x: win.shown ? 0 : 24
                Behavior on x { NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpatial } }
            }

            Image {
                anchors.fill: parent
                anchors.margins: 8
                source: win.path.length > 0 ? ("file://" + win.path) : ""
                fillMode: Image.PreserveAspectFit
                cache: false
                asynchronous: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Quickshell.execDetached(["sh", "-c", "xdg-open \"$1\" 2>/dev/null || pcmanfm \"$1\"", "sh", win.path]);
                    win.shown = false;
                }
            }

            // dismiss button
            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 4
                width: 20; height: 20; radius: 10
                visible: thumbHover.hovered
                color: xMA.containsMouse ? Theme.base08 : Theme.base02
                Text {
                    anchors.centerIn: parent; text: "󰅖"
                    color: xMA.containsMouse ? Theme.base00 : Theme.base05
                    font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize - 4
                }
                MouseArea { id: xMA; anchors.fill: parent; hoverEnabled: true; onClicked: win.shown = false }
            }
            HoverHandler { id: thumbHover }
        }
    }
}
