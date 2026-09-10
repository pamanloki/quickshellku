import QtQuick
import "root:/services"

// custom/power equivalent (base08). Opens the power menu.
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
        color: Theme.base08

        Text {
            id: label
            anchors.centerIn: parent
            text: "󰐥"
            color: Theme.base00
            font.family: Theme.fontFamilyFallback
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Globals.togglePower()
    }
}
