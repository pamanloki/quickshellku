import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Flavours theme picker (Base16 / Base24). Lists installed schemes, marks the
// current one, applies on click, and toggles light/dark. Attached to the bar.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.themeOpen || slide.y > -box.height
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "quickshell:theme"

        readonly property var filtered: {
            const q = filter.text.toLowerCase().trim();
            if (q.length === 0) return Flavours.families;
            return Flavours.families.filter(s => s.toLowerCase().includes(q));
        }

        onVisibleChanged: {
            if (visible) {
                Flavours.refresh();
                filter.text = "";
                filter.forceActiveFocus();
            }
        }

        MouseArea { anchors.fill: parent; onClicked: Globals.themeOpen = false }

        Rectangle {
            id: box
            transform: Translate {
                id: slide
                y: Globals.themeOpen ? 0 : -box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }

            width: 340
            height: 440
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 8
            anchors.topMargin: Theme.menuBarHeight + 1
            radius: 20
            color: Theme.base00
            border.width: 1
            border.color: Theme.base02
            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // header + light/dark toggle
                Row {
                    width: parent.width
                    Text {
                        text: "󰸌  Theme"
                        color: Theme.base05
                        font.family: Theme.fontFamilyFallback
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: Theme.fontWeight
                        width: parent.width - 96
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: 96; height: 30; radius: 8
                        color: togH.hovered ? Theme.base02 : Theme.base01
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent
                            text: "󰔎  Toggle"
                            color: Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize - 3
                        }
                        HoverHandler { id: togH }
                        MouseArea { anchors.fill: parent; onClicked: Flavours.toggle() }
                    }
                }

                // search
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 8
                    color: Theme.base01
                    border.color: filter.activeFocus ? Theme.base0D : "transparent"
                    border.width: 2
                    Text {
                        id: fIcon
                        anchors.left: parent.left; anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""; color: Theme.base0D
                        font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize
                    }
                    TextInput {
                        id: filter
                        anchors.left: fIcon.right; anchors.leftMargin: 10
                        anchors.right: parent.right; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.base05
                        font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 1
                        clip: true
                        Keys.onEscapePressed: Globals.themeOpen = false
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search schemes…"
                            color: Theme.base03
                            font: filter.font
                            visible: filter.text.length === 0
                        }
                    }
                }

                ListView {
                    id: list
                    width: parent.width
                    height: parent.height - 38 - 30 - 10 - 10
                    clip: true
                    model: win.filtered
                    spacing: 3
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        required property var modelData
                        width: list.width
                        height: 36
                        radius: 8
                        readonly property bool isCurrent: Flavours.currentFamily === modelData
                        color: isCurrent ? Theme.base02 : (rowH.hovered ? Theme.base01 : "transparent")

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 44
                            text: Flavours.title(modelData)
                            color: Theme.base05
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            elide: Text.ElideRight
                        }
                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.isCurrent ? "󰄬" : ""
                            color: Theme.base0B
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize
                        }

                        HoverHandler { id: rowH }
                        MouseArea { anchors.fill: parent; onClicked: Flavours.applyFamily(modelData) }
                    }
                }
            }
        }
    }
}
