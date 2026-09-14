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
        margins.top: Theme.menuBarHeight + 8
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
                    required property int index
                    width: col.width
                    // macOS caps on-screen toasts; overflow waits in the centre
                    visible: index < 4
                    implicitHeight: index < 4 ? (content.y + content.implicitHeight + 12) : 0
                    clip: true
                    radius: 16
                    color: Theme.base01
                    border.width: 1
                    border.color: card.critical ? Theme.base08 : Theme.base02

                    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                    readonly property bool low: modelData.urgency === NotificationUrgency.Low
                    readonly property var actions: modelData.actions || []

                    // enter animation
                    opacity: 0
                    x: 20
                    Component.onCompleted: { opacity = 1; x = 0; }
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                    Behavior on x { NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpatial } }

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
                        width: 38; height: 38; radius: 9
                        color: Theme.base02
                        Image {
                            anchors.centerIn: parent
                            width: 28; height: 28
                            sourceSize.width: 28; sourceSize.height: 28
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

                    // close button — only on hover, macOS-style
                    Rectangle {
                        id: closeBtn
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        width: 22; height: 22; radius: 11
                        visible: hover.hovered
                        color: closeHover.hovered ? Theme.base08 : Theme.base02
                        z: 2
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: closeHover.hovered ? Theme.base00 : Theme.base05
                            font.family: Theme.fontFamilyFallback
                            font.pixelSize: Theme.fontSize - 2
                        }
                        HoverHandler { id: closeHover }
                        MouseArea { anchors.fill: parent; onClicked: card.modelData.dismiss() }
                    }

                    Column {
                        id: content
                        x: iconBox.x + iconBox.width + 10
                        y: 12
                        width: parent.width - x - 12
                        spacing: 2

                        Text {
                            width: parent.width
                            text: card.modelData.appName || "Notification"
                            color: card.critical ? Theme.base08 : Theme.base04
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 4
                            font.weight: Theme.fontWeight
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: card.modelData.summary || ""
                            color: Theme.base05
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight: Theme.fontWeight
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }
                        Text {
                            width: parent.width
                            text: card.modelData.body || ""
                            color: Theme.base05
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            textFormat: Text.StyledText
                            wrapMode: Text.WordWrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }

                        // action buttons
                        Row {
                            width: parent.width
                            spacing: 6
                            topPadding: 4
                            visible: card.actions.length > 0
                            Repeater {
                                model: card.actions
                                delegate: Rectangle {
                                    required property var modelData
                                    height: 26
                                    width: Math.min(140, actLabel.implicitWidth + 22)
                                    radius: 8
                                    color: actHover.hovered ? Theme.accent : Theme.base02
                                    Text {
                                        id: actLabel
                                        anchors.centerIn: parent
                                        text: parent.modelData.text || parent.modelData.identifier || "Open"
                                        color: actHover.hovered ? Theme.base00 : Theme.base05
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize - 3
                                        font.weight: Theme.fontWeight
                                        elide: Text.ElideRight
                                    }
                                    HoverHandler { id: actHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            parent.modelData.invoke();
                                            card.modelData.dismiss();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // click card to dismiss (below the action buttons / close)
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
