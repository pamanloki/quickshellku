import QtQuick
import "root:/services"

// Update indicator: icon + pending count. Hidden when everything is up to date.
// Left-click opens a terminal to upgrade; right-click re-checks now.
Item {
    id: root
    visible: Updates.count > 0
    implicitWidth: visible ? Math.round(pill.width) : 0
    implicitHeight: Theme.barHeight

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight - 2 * Theme.pillVMargin
        radius: Theme.radius
        color: Theme.base02
        width: Math.round(row.implicitWidth) + 2 * Theme.pillHPad

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰚰"
                color: Theme.base0A
                font.family: Theme.fontFamilyFallback
                font.pixelSize: Theme.fontSize + 1
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Updates.count
                color: Theme.base05
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
                font.features: ({ "tnum": 1 })
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Updates.refresh();
            else
                Updates.runUpdate();
        }
    }
}
