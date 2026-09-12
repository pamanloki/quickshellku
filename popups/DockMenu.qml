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
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:dockmenu"

        // Escape to close
        Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: Globals.dockMenuOpen = false }
        // click-away
        MouseArea { anchors.fill: parent; onClicked: Globals.dockMenuOpen = false }

        Rectangle {
            id: menuBox
            width: 300
            height: menuCol.implicitHeight + 10
            radius: 10
            color: Theme.base01
            border.width: 1
            border.color: Theme.base02

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10   // parent already ends at the dock's top edge
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
                        height: 38
                        radius: 8
                        color: itemMA.containsMouse ? Theme.base02 : "transparent"

                        Image {
                            id: appIcon
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22; height: 22
                            sourceSize.width: 22; sourceSize.height: 22
                            source: modelData.icon
                            fillMode: Image.PreserveAspectFit
                        }
                        readonly property bool canMinMax: Niri.isMinimizable(modelData.id)

                        Text {
                            anchors.left: appIcon.right; anchors.leftMargin: 10
                            anchors.right: btnRow.left; anchors.rightMargin: 8
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

                        // window action buttons (minimize / maximize / close)
                        Row {
                            id: btnRow
                            anchors.right: parent.right; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            // minimize
                            Rectangle {
                                width: 22; height: 22; radius: 11
                                visible: parent.parent.canMinMax
                                color: minMA.containsMouse ? Theme.base03 : Theme.base02
                                Text {
                                    anchors.centerIn: parent; text: "󰖰"
                                    color: Theme.base05
                                    font.family: Theme.fontFamilyFallback
                                    font.pixelSize: Theme.fontSize - 4
                                }
                                MouseArea {
                                    id: minMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: { Niri.setMinimized(modelData.id, true); Globals.dockMenuOpen = false; }
                                }
                            }

                            // maximize (toggle)
                            Rectangle {
                                width: 22; height: 22; radius: 11
                                visible: parent.parent.canMinMax
                                color: maxMA.containsMouse ? Theme.base03 : Theme.base02
                                Text {
                                    anchors.centerIn: parent; text: "󰖯"
                                    color: Theme.base05
                                    font.family: Theme.fontFamilyFallback
                                    font.pixelSize: Theme.fontSize - 4
                                }
                                MouseArea {
                                    id: maxMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: { Niri.toggleMaximize(modelData.id); Globals.dockMenuOpen = false; }
                                }
                            }

                            // close (red X)
                            Rectangle {
                                id: killBtn
                                width: 22; height: 22; radius: 11
                                color: killMA.containsMouse ? Qt.lighter(Theme.base08, 1.2) : Theme.base08
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: Theme.base00
                                    font.family: Theme.fontFamilyFallback
                                    font.pixelSize: Theme.fontSize - 4
                                }
                                MouseArea {
                                    id: killMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        Niri.closeWindow(modelData.id);
                                        // drop just this row; keep the panel open
                                        Globals.dockMenuWindows = Globals.dockMenuWindows.filter(w => w.id !== modelData.id);
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {   // separator above the pin toggle
                    visible: Globals.dockMenuWindows.length > 0
                    width: menuCol.width - 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 1
                    color: Theme.base03
                }
                Rectangle {   // Keep in Dock / Remove from Dock
                    width: menuCol.width
                    height: 34
                    radius: 8
                    color: pinMA.containsMouse ? Theme.base02 : "transparent"
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: DockConfig.isPinned(Globals.dockMenuAppId) ? "Remove from Dock" : "Keep in Dock"
                        color: Theme.base05
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }
                    MouseArea {
                        id: pinMA
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (DockConfig.isPinned(Globals.dockMenuAppId)) DockConfig.unpin(Globals.dockMenuAppId);
                            else DockConfig.pin(Globals.dockMenuAppId);
                            Globals.dockMenuOpen = false;
                        }
                    }
                }
            }
        }
    }
}
