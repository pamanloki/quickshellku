import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Context menu for a system-tray item, shown above the bar on right-click.
// Renders the app's real menu via QsMenuOpener, with submenu drill-down,
// separators, disabled entries and checkboxes.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.trayMenuOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:traymenu"

        // Handle stack for submenu navigation.
        property var stack: []
        readonly property var currentHandle: stack.length > 0 ? stack[stack.length - 1] : null

        onVisibleChanged: stack = (visible && Globals.trayMenuHandle) ? [Globals.trayMenuHandle] : []

        QsMenuOpener {
            id: opener
            menu: win.currentHandle
        }

        MouseArea { anchors.fill: parent; onClicked: Globals.trayMenuOpen = false }

        Rectangle {
            id: menuBox
            width: 240
            height: menuCol.implicitHeight + 10
            radius: 10
            color: Theme.base01
            border.width: 1
            border.color: Theme.base02

            anchors.top: parent.top
            anchors.topMargin: Theme.menuBarHeight + 6
            x: Math.max(8, Math.min(Globals.trayMenuX - width / 2, parent.width - width - 8))

            opacity: win.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEffects } }
            transformOrigin: Item.Top
            scale: win.visible ? 1 : 0.92
            Behavior on scale { NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpatial } }

            MouseArea { anchors.fill: parent }   // swallow clicks inside

            Column {
                id: menuCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 5
                spacing: 1

                // back row (in a submenu)
                Rectangle {
                    width: parent.width
                    height: 30
                    radius: 7
                    visible: win.stack.length > 1
                    color: backMA.containsMouse ? Theme.base02 : "transparent"
                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Text { text: "󰅁"; color: Theme.base05; font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Back"; color: Theme.base05; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 2; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        id: backMA
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: win.stack = win.stack.slice(0, win.stack.length - 1)
                    }
                }

                Repeater {
                    model: opener.children

                    delegate: Item {
                        id: entry
                        required property var modelData
                        width: menuCol.width
                        implicitHeight: modelData.isSeparator ? 9 : 30

                        // separator
                        Rectangle {
                            visible: entry.modelData.isSeparator
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            height: 1
                            color: Theme.base03
                        }

                        // normal item
                        Rectangle {
                            visible: !entry.modelData.isSeparator
                            anchors.fill: parent
                            radius: 7
                            color: itemMA.containsMouse && entry.modelData.enabled ? Theme.base02 : "transparent"

                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 10
                                anchors.right: chev.left; anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                text: (entry.modelData.checkState === Qt.Checked ? "󰄬  " : "") + (entry.modelData.text || "")
                                color: entry.modelData.enabled ? Theme.base05 : Theme.base03
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                elide: Text.ElideRight
                            }
                            Text {
                                id: chev
                                anchors.right: parent.right; anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                visible: entry.modelData.hasChildren
                                text: "󰅂"
                                color: Theme.base04
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: Theme.fontSize - 2
                            }

                            MouseArea {
                                id: itemMA
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: entry.modelData.enabled
                                onClicked: {
                                    if (entry.modelData.hasChildren)
                                        win.stack = win.stack.concat([entry.modelData]);
                                    else {
                                        entry.modelData.triggered();
                                        Globals.trayMenuOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
