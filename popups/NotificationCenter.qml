import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "root:/services"

// Notification history / center. Opened from the bar bell. Lists past
// notifications (persisted copies), with a Do Not Disturb toggle and Clear All.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.notifsOpen || slide.y < box.height
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:notifcenter"

        onVisibleChanged: if (visible) Notifications.markRead()

        function ago(ms) {
            const s = Math.max(0, Math.floor((Date.now() - ms) / 1000));
            if (s < 60) return "now";
            const m = Math.floor(s / 60);
            if (m < 60) return m + "m";
            const h = Math.floor(m / 60);
            if (h < 24) return h + "h";
            return Math.floor(h / 24) + "d";
        }

        MouseArea { anchors.fill: parent; onClicked: Globals.notifsOpen = false }

        Item {
            id: box
            transform: Translate {
                id: slide
                y: Globals.notifsOpen ? 0 : box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }

            width: 384
            height: 500
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 8
            anchors.bottomMargin: 0
            IslandBg { anchors.fill: parent; radius: 16 }
            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // header
                Item {
                    width: parent.width
                    height: 30
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰂚  Notifications"
                        color: Theme.base05
                        font.family: Theme.fontFamilyFallback
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: Theme.fontWeight
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        // DND toggle
                        Rectangle {
                            width: 72; height: 30; radius: 8
                            color: Notifications.doNotDisturb ? Theme.base08 : (dndMA.containsMouse ? Theme.base02 : Theme.base01)
                            Text {
                                anchors.centerIn: parent
                                text: Notifications.doNotDisturb ? "󰂛 DND" : "󰂚 DND"
                                color: Notifications.doNotDisturb ? Theme.base00 : Theme.base05
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: Theme.fontSize - 3
                            }
                            MouseArea {
                                id: dndMA
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Notifications.doNotDisturb = !Notifications.doNotDisturb
                            }
                        }
                        // clear all
                        Rectangle {
                            width: 72; height: 30; radius: 8
                            color: clMA.containsMouse ? Theme.base08 : Theme.base01
                            Text {
                                anchors.centerIn: parent
                                text: "󰩺 Clear"
                                color: clMA.containsMouse ? Theme.base00 : Theme.base05
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: Theme.fontSize - 3
                            }
                            MouseArea {
                                id: clMA
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Notifications.clearHistory()
                            }
                        }
                    }
                }

                // empty state
                Text {
                    visible: Notifications.history.length === 0
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 40
                    text: "󰂜\nNo notifications"
                    color: Theme.base03
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: Theme.fontSize + 4
                }

                // history list
                ListView {
                    id: list
                    width: parent.width
                    height: parent.height - 38 - 10
                    clip: true
                    spacing: 8
                    visible: Notifications.history.length > 0
                    model: Notifications.history
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        width: list.width
                        implicitHeight: Math.max(58, bodyT.y + bodyT.paintedHeight + 10)
                        radius: 12
                        color: Theme.base01
                        border.width: 2
                        border.color: card.modelData.urgency === NotificationUrgency.Critical
                            ? Theme.base08 : "transparent"

                        Rectangle {
                            id: ic
                            x: 10; y: 10
                            width: 34; height: 34; radius: 8
                            color: Theme.base02
                            Image {
                                anchors.centerIn: parent
                                width: 24; height: 24
                                sourceSize.width: 24; sourceSize.height: 24
                                fillMode: Image.PreserveAspectFit
                                source: {
                                    if (card.modelData.image && card.modelData.image.length > 0)
                                        return card.modelData.image;
                                    if (card.modelData.appIcon && card.modelData.appIcon.length > 0)
                                        return Quickshell.iconPath(card.modelData.appIcon, "dialog-information");
                                    return Quickshell.iconPath("dialog-information");
                                }
                            }
                        }

                        Text {
                            id: appT
                            x: ic.x + ic.width + 10
                            y: 10
                            width: parent.width - x - 76
                            text: card.modelData.appName
                            color: Theme.base0D
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 4
                            font.weight: Theme.fontWeight
                            elide: Text.ElideRight
                        }
                        Text {
                            id: timeT
                            anchors.right: closeB.left
                            anchors.rightMargin: 6
                            y: 10
                            text: win.ago(card.modelData.time)
                            color: Theme.base04
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 4
                        }
                        Rectangle {
                            id: closeB
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            y: 8
                            width: 20; height: 20; radius: 10
                            color: xH.hovered ? Theme.base08 : "transparent"
                            Text {
                                anchors.centerIn: parent; text: "󰅖"
                                color: xH.hovered ? Theme.base00 : Theme.base05
                                font.family: Theme.fontFamilyFallback
                                font.pixelSize: Theme.fontSize - 2
                            }
                            HoverHandler { id: xH }
                            MouseArea { anchors.fill: parent; onClicked: Notifications.removeHistory(card.modelData.id) }
                        }

                        Text {
                            id: sumT
                            x: appT.x
                            y: appT.y + appT.paintedHeight + 2
                            width: parent.width - x - 12
                            text: card.modelData.summary
                            color: Theme.base05
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            font.weight: Theme.fontWeight
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }
                        Text {
                            id: bodyT
                            x: appT.x
                            y: sumT.visible ? sumT.y + sumT.paintedHeight + 2 : sumT.y
                            width: parent.width - x - 12
                            text: card.modelData.body
                            color: Theme.base04
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                            textFormat: Text.StyledText
                            wrapMode: Text.WordWrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }
                    }
                }
            }
        }
    }
}
