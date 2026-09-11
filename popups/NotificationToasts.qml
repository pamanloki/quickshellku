import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "root:/services"

// Toast popups for incoming notifications, top-right. Auto-dismiss (paused on
// hover), colour-coded by urgency, click to dismiss, action buttons.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; right: true }
        margins.top: 10
        margins.right: 10
        implicitWidth: 370
        implicitHeight: Math.max(1, col.implicitHeight)
        color: "transparent"
        visible: Notifications.list.values.length > 0
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:notifications"

        Column {
            id: col
            width: parent.width
            spacing: 8

            Repeater {
                model: Notifications.list

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    width: col.width
                    implicitHeight: Math.max(64, body.y + body.paintedHeight + 12)
                    radius: 12
                    color: Theme.base01
                    border.width: 2
                    border.color: card.critical ? Theme.base08
                        : card.low ? Theme.base02 : Theme.base0D

                    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                    readonly property bool low: modelData.urgency === NotificationUrgency.Low

                    // enter animation
                    opacity: 0
                    x: 20
                    Component.onCompleted: { opacity = 1; x = 0; }
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                    Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    // auto-dismiss (paused while hovered; never for critical)
                    Timer {
                        running: !hover.hovered && !card.critical
                        interval: modelData.expireTimeout > 0 ? modelData.expireTimeout : 5000
                        onTriggered: modelData.dismiss()
                    }
                    HoverHandler { id: hover }

                    // app icon / image
                    Rectangle {
                        id: iconBox
                        x: 12; y: 12
                        width: 36; height: 36; radius: 8
                        color: Theme.base02
                        Image {
                            anchors.centerIn: parent
                            width: 26; height: 26
                            sourceSize.width: 26; sourceSize.height: 26
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

                    // close button
                    Rectangle {
                        id: closeBtn
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        width: 22; height: 22; radius: 11
                        color: closeHover.hovered ? Theme.base08 : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: closeHover.hovered ? Theme.base00 : Theme.base03
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize - 2
                        }
                        HoverHandler { id: closeHover }
                        MouseArea { anchors.fill: parent; onClicked: card.modelData.dismiss() }
                    }

                    Text {
                        id: appLabel
                        x: iconBox.x + iconBox.width + 10
                        y: 12
                        width: parent.width - x - 38
                        text: card.modelData.appName || "Notification"
                        color: card.critical ? Theme.base08 : Theme.base0D
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 4
                        font.weight: Theme.fontWeight
                        elide: Text.ElideRight
                    }
                    Text {
                        id: summary
                        x: appLabel.x
                        y: appLabel.y + appLabel.paintedHeight + 2
                        width: parent.width - x - 16
                        text: card.modelData.summary || ""
                        color: Theme.base05
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Theme.fontWeight
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }
                    Text {
                        id: body
                        x: appLabel.x
                        y: summary.visible ? summary.y + summary.paintedHeight + 2 : summary.y
                        width: parent.width - x - 16
                        text: card.modelData.body || ""
                        color: Theme.base04
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                        textFormat: Text.StyledText
                        wrapMode: Text.WordWrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }

                    // click body area to dismiss
                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: card.modelData.dismiss()
                    }
                }
            }
        }
    }
}
