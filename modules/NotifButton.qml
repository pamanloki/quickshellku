import QtQuick
import "root:/services"

// Bell button: opens the Notification Center. Shows a bell-off glyph while DND
// is on, and an accent dot when there are unread notifications.
Item {
    id: root
    implicitWidth: pill.implicitWidth
    implicitHeight: Theme.barHeight

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight - 2 * Theme.pillVMargin
        implicitWidth: label.implicitWidth + 2 * Theme.pillHPad
        radius: Theme.radius
        color: Theme.base02

        Text {
            id: label
            anchors.centerIn: parent
            text: Notifications.doNotDisturb ? "󰂛" : "󰂚"
            color: Notifications.doNotDisturb ? Theme.base08 : Theme.base05
            font.family: Theme.fontFamilyFallback
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }

        // unread dot
        Rectangle {
            visible: Notifications.unread > 0 && !Notifications.doNotDisturb
            width: 7; height: 7; radius: 4
            color: Theme.base08
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 5
            anchors.topMargin: 5
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Globals.toggleNotifs()
    }
}
