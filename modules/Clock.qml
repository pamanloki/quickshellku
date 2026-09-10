import QtQuick
import Quickshell
import "root:/services"

// Clock pill: inverse colours (base05 bg, base00 fg) like your Waybar.
// Left click toggles between time and full date (format-alt).
Item {
    id: root
    implicitWidth: pill.implicitWidth
    implicitHeight: Theme.barHeight
    property bool showDate: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight - 2 * Theme.pillVMargin
        implicitWidth: label.implicitWidth + 2 * Theme.pillHPad
        radius: Theme.radius
        color: Theme.base05

        Text {
            id: label
            anchors.centerIn: parent
            color: Theme.base00
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            text: root.showDate
                ? Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy")
                : Qt.formatDateTime(clock.date, "HH:mm t")
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.showDate = !root.showDate
    }
}
