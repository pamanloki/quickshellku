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
        visible: Globals.wifiOpen || slide.y < box.height
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

        Item {
            id: box
            transform: Translate {
                id: slide
                y: Globals.wifiOpen ? 0 : box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }
            width: 360
            height: 440
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 8
            anchors.bottomMargin: 0
            IslandBg { anchors.fill: parent; radius: 8 }

            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header + radio toggle
                Row {
                    width: parent.width
                    Text {
                        text: "󰤨  Wi-Fi"
                        color: Theme.base05
                        font.family: Theme.fontFamilyFallback
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: Theme.fontWeight
                        width: parent.width - 60
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: 52; height: 26; radius: 13
                        color: Network.radioOn ? Theme.base0B : Theme.base03
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
                    color: Network.connected ? Theme.base0B : Theme.base03
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    elide: Text.ElideRight
                }

                // Scan + manage buttons
                Row {
                    width: parent.width
                    spacing: 8
                    Rectangle {
                        width: (parent.width - 8) / 2; height: 30; radius: 4
                        color: Theme.base02
                        Text {
                            anchors.centerIn: parent
                            text: Network.scanning ? "Scanning…" : "󰑐  Scan"
                            color: Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize - 2
                        }
                        MouseArea { anchors.fill: parent; onClicked: Network.scan() }
                    }
                    Rectangle {
                        width: (parent.width - 8) / 2; height: 30; radius: 4
                        color: Theme.base02
                        Text {
                            anchors.centerIn: parent
                            text: "  impala"
                            color: Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize - 2
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Quickshell.execDetached(["footx", "-e", "-f", "impala"]);
                                Globals.wifiOpen = false;
                            }
                        }
                    }
                }

                ListView {
                    id: netList
                    width: parent.width
                    height: parent.height - 170
                    clip: true
                    model: Network.networks
                    spacing: 4

                    delegate: Rectangle {
                        id: netItem
                        required property var modelData
                        width: netList.width
                        height: selected ? 78 : 38
                        readonly property bool selected: win.selectedSsid === modelData.ssid
                        color: modelData.connected ? Theme.base02 : Theme.base01
                        radius: 4
                        Behavior on height { NumberAnimation { duration: 100 } }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6
                            Row {
                                width: parent.width
                                Text {
                                    text: (modelData.connected ? "󰤨  " : "󰤟  ") + modelData.ssid
                                    color: Theme.base05
                                    font.family: Theme.fontFamilyFallback
                                    font.pixelSize: Theme.fontSize - 1
                                    width: parent.width - 60
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: modelData.security || ""
                                    color: Theme.base03
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 4
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Passphrase row (expands when selected).
                            Row {
                                width: parent.width
                                spacing: 6
                                visible: netItem.selected && !modelData.connected
                                Rectangle {
                                    width: parent.width - 76; height: 28; radius: 4
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
                                    width: 70; height: 28; radius: 4; color: Theme.base0B
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
