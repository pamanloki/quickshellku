import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Native WiFi panel over iwd. Toggle radio, scan, connect (with passphrase
// for new secured networks). "Manage in impala" is always available.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.wifiOpen || slide.y > -box.height
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "quickshell:wifi"

        property string selectedSsid: ""

        onVisibleChanged: {
            if (visible) {
                Network.refresh();
                Network.scan();
                selectedSsid = "";
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Globals.wifiOpen = false
        }

        Rectangle {
            id: box
            transform: Translate {
                id: slide
                y: Globals.wifiOpen ? 0 : -box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }
            width: 360
            height: 440
            x: Globals.panelX < 0
                ? (parent.width - width - 8)
                : Math.max(8, Math.min(parent.width - width - 8, Globals.panelX - width / 2))
            anchors.top: parent.top
            anchors.topMargin: 4
            radius: 20
            color: Theme.base00
            border.width: 1
            border.color: Theme.base02

            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header: title + refresh + radio toggle
                Row {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: "Wi-Fi"
                        color: Theme.base05
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: Theme.fontWeight
                        width: parent.width - 96
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {   // refresh / scan
                        width: 28; height: 26; radius: 8
                        anchors.verticalCenter: parent.verticalCenter
                        color: rescanMA.containsMouse ? Theme.base02 : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰑐"
                            color: Network.scanning ? Theme.accent : Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize
                        }
                        MouseArea { id: rescanMA; anchors.fill: parent; hoverEnabled: true; onClicked: Network.scan() }
                    }
                    Rectangle {   // radio toggle
                        width: 52; height: 26; radius: 13
                        color: Network.radioOn ? Theme.accent : Theme.base03
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            width: 20; height: 20; radius: 10; color: Theme.base00
                            anchors.verticalCenter: parent.verticalCenter
                            x: Network.radioOn ? parent.width - width - 3 : 3
                            Behavior on x { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Network.setRadio(!Network.radioOn)
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: Network.connected
                        ? ("Connected: " + Network.ssid + "  (" + Network.signalStrength + "%)")
                        : "Not connected"
                    color: Network.connected ? Theme.accent : Theme.base03
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    elide: Text.ElideRight
                }


                ListView {
                    id: netList
                    width: parent.width
                    height: parent.height - 120
                    clip: true
                    model: Network.networks
                    spacing: 4

                    delegate: Rectangle {
                        id: netItem
                        required property var modelData
                        width: netList.width
                        height: selected ? 78 : 38
                        readonly property bool selected: win.selectedSsid === modelData.ssid
                        color: modelData.connected ? Theme.base02 : (rowHover.hovered ? Theme.base01 : "transparent")
                        radius: 10
                        Behavior on height { NumberAnimation { duration: 100 } }
                        HoverHandler { id: rowHover }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6
                            Row {
                                width: parent.width
                                spacing: 6
                                Text {
                                    text: modelData.connected ? "󰤨" : "󰤟"
                                    color: Theme.base05
                                    font.family: Theme.fontFamilyFallback
                                    font.pixelSize: Theme.fontSize - 1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: modelData.ssid
                                    color: Theme.base05
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 1
                                    width: parent.width - 104
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {   // lock icon for secured networks (macOS-style)
                                    readonly property string _sec: (modelData.security || "").toLowerCase()
                                    text: "󰌾"
                                    color: Theme.base04
                                    font.family: Theme.fontFamilyFallback
                                    font.pixelSize: Theme.fontSize - 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: _sec.length > 0 && _sec !== "open" && _sec !== "none" && _sec !== "--"
                                }
                                Text {
                                    text: modelData.connected ? "󰄬" : ""
                                    color: Theme.accent
                                    font.family: Theme.fontFamilyFallback
                                    font.pixelSize: Theme.fontSize - 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: modelData.connected
                                }
                            }

                            // Passphrase row (expands when selected).
                            Row {
                                width: parent.width
                                spacing: 6
                                visible: netItem.selected && !modelData.connected
                                Rectangle {
                                    width: parent.width - 76; height: 28; radius: 10
                                    color: Theme.base00
                                    border.color: Theme.base03; border.width: 1
                                    TextInput {
                                        id: passInput
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        color: Theme.base05
                                        echoMode: TextInput.Password
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize - 2
                                        clip: true
                                        Text {
                                            text: "passphrase"
                                            color: Theme.base03
                                            font: passInput.font
                                            visible: passInput.text.length === 0
                                        }
                                    }
                                }
                                Rectangle {
                                    width: 70; height: 28; radius: 10; color: Theme.accent
                                    Text {
                                        anchors.centerIn: parent; text: "Connect"
                                        color: Theme.base00
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize - 3
                                        font.weight: Theme.fontWeight
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            Network.connect(modelData.ssid, passInput.text);
                                            win.selectedSsid = "";
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            z: -1
                            onClicked: {
                                if (modelData.connected) {
                                    Network.disconnect();
                                } else {
                                    // Try known-network connect immediately; if it
                                    // needs a passphrase, expand for input.
                                    win.selectedSsid = win.selectedSsid === modelData.ssid ? "" : modelData.ssid;
                                    Network.connect(modelData.ssid, "");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
