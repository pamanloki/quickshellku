import QtQuick
import Quickshell
import "root:/services"

// Clock pill: inverse colours (base05 bg, base00 fg) like your Waybar.
// Left click toggles between time and full date (format-alt).
//
// Anti-flicker: SystemClock can briefly expose an invalid `date` on a tick,
// which made Qt.formatDateTime return "" and the label blank+reappear every
// second. We keep the formatted string in `timeText` and only replace it when
// the new value is non-empty AND actually different, so the label (and the
// width-driven pill) never churn between updates.
Item {
    id: root
    implicitWidth: pill.implicitWidth
    implicitHeight: Theme.barHeight
    property bool showDate: false
    property string timeText: "--:--"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function refresh() {
        if (!clock.date)
            return;
        const s = Qt.formatDateTime(clock.date,
            root.showDate ? "dddd, dd MMMM yyyy" : "HH:mm t");
        if (s && s.length > 0 && s !== root.timeText)
            root.timeText = s;
    }

    Component.onCompleted: refresh()
    onShowDateChanged: refresh()

    Connections {
        target: clock
        function onDateChanged() { root.refresh(); }
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
            text: root.timeText
            color: Theme.base00
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.showDate = !root.showDate
    }
}
