import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Right-click a dock icon → pick which window of that app to focus (macOS-style).
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.dockMenuOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:dockmenu"

        MouseArea { anchors.fill: parent; onClicked: Globals.dockMenuOpen = false }

        Rectangle {
            id: menuBox
            width: 260
            height: menuCol.implicitHeight + 10
            radius: 10
            color: Theme.base01
            border.width: 1
            border.color: Theme.base02

            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.dockIconSize + 22 + 18
            x: Math.max(8, Math.min(Globals.dockMenuX - width / 2, parent.width - width - 8))

            opacity: win.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEffects } }
            transformOrigin: Item.Bottom
            scale: win.visible ? 1 : 0.92
            Behavior on scale { NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpatial } }

            MouseArea { anchors.fill: parent }

            Column {
                id: menuCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 5
                spacing: 1

                Repeater {
                    model: Globals.dockMenuWindows
                    delegate: Rectangle {
                        required property var modelData
                        width: menuCol.width
                        height: 30
                        radius: 7
                        color: itemMA.containsMouse ? Theme.base02 : "transparent"
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 10
                            anchors.right: parent.right; anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.title
                            color: Theme.base05
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            elide: Text.ElideRight
                        }
                        MouseArea {
                            id: itemMA
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { Niri.focusWindow(modelData.id); Globals.dockMenuOpen = false; }
                        }
                    }
                }
            }
        }
    }
}
