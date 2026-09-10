import QtQuick
import "root:/services"

// Clock pill: inverse colours (base05 bg, base00 fg) like your Waybar.
// Left click toggles between time and full date.
//
// Anti-flicker, mirroring noctalia's clock:
//   * a shared Timer-based Time singleton (not SystemClock)
//   * timeText only changes when the visible string actually changes, so the
//     label never blanks/relays between minutes
//   * the capsule width is Math.round()-ed and the digits use tabular figures
//     (tnum), so there is no subpixel width jitter that would relayout — and
//     repaint — the pill and everything to its right every tick
Item {
    id: root
    implicitWidth: Math.round(pill.width)
    implicitHeight: Theme.barHeight
    property bool showDate: false
    property string timeText: "--:--"

    function refresh() {
        const d = Time.now;
        if (!d)
            return;
        const s = Qt.formatDateTime(d, root.showDate ? "dddd, dd MMMM yyyy" : "HH:mm t");
        if (s && s.length > 0 && s !== root.timeText)
            root.timeText = s;
    }

    Component.onCompleted: refresh()
    onShowDateChanged: refresh()
    Connections {
        target: Time
        function onNowChanged() { root.refresh(); }
    }

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight - 2 * Theme.pillVMargin
        width: Math.round(label.implicitWidth) + 2 * Theme.pillHPad
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
            // tabular figures: every digit is the same width, so the string
            // width is constant across minute changes (no jitter).
            font.features: ({ "tnum": 1 })
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.showDate = !root.showDate
    }
}
