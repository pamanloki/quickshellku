import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Month calendar, opened by right-clicking the clock. Attached to the bar.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.calendarOpen || slide.y > -box.height
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:calendar"

        property int viewYear: 2000
        property int viewMonth: 0   // 0-11

        function resetToToday() {
            const d = Time.now;
            viewYear = d.getFullYear();
            viewMonth = d.getMonth();
        }
        function shift(delta) {
            let m = viewMonth + delta;
            let y = viewYear;
            while (m < 0) { m += 12; y--; }
            while (m > 11) { m -= 12; y++; }
            viewMonth = m; viewYear = y;
        }

        readonly property var cells: {
            const first = new Date(viewYear, viewMonth, 1);
            const offset = (first.getDay() + 6) % 7; // Monday-first
            const dim = new Date(viewYear, viewMonth + 1, 0).getDate();
            const arr = [];
            for (let i = 0; i < 42; i++) {
                const n = i - offset + 1;
                arr.push(n >= 1 && n <= dim ? n : 0);
            }
            return arr;
        }
        readonly property var today: Time.now
        readonly property bool showsThisMonth: today.getFullYear() === viewYear && today.getMonth() === viewMonth

        onVisibleChanged: if (visible) resetToToday()

        MouseArea { anchors.fill: parent; onClicked: Globals.calendarOpen = false }

        Item {
            id: box
            transform: Translate {
                id: slide
                y: Globals.calendarOpen ? 0 : -box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }

            width: 320
            height: col.implicitHeight + 24
            x: Globals.panelX < 0
                ? (parent.width - width - 8)
                : Math.max(8, Math.min(parent.width - width - 8, Globals.panelX - width / 2))
            anchors.top: parent.top
            anchors.topMargin: Theme.menuBarHeight + 1
            Rectangle { anchors.fill: parent; radius: 18; color: Theme.base00; border.width: 1; border.color: Theme.base02 }
            MouseArea { anchors.fill: parent }

            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

                // header: month year + nav
                Row {
                    width: parent.width
                    Text {
                        text: Qt.formatDate(new Date(win.viewYear, win.viewMonth, 1), "MMMM yyyy")
                        color: Theme.base05
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.weight: Theme.fontWeight
                        width: parent.width - 72
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: prevH.hovered ? Theme.base02 : "transparent"
                        anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "󰅁"; color: Theme.base05; font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize }
                        HoverHandler { id: prevH }
                        MouseArea { anchors.fill: parent; onClicked: win.shift(-1) }
                    }
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: nextH.hovered ? Theme.base02 : "transparent"
                        anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "󰅂"; color: Theme.base05; font.family: Theme.fontFamilyFallback; font.pixelSize: Theme.fontSize }
                        HoverHandler { id: nextH }
                        MouseArea { anchors.fill: parent; onClicked: win.shift(1) }
                    }
                }

                // weekday header
                Row {
                    width: parent.width
                    Repeater {
                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                        delegate: Text {
                            required property var modelData
                            width: (col.width) / 7
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: Theme.base05
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 4
                            font.weight: Theme.fontWeight
                        }
                    }
                }

                // day grid
                Grid {
                    width: parent.width
                    columns: 7
                    rowSpacing: 2
                    Repeater {
                        model: win.cells
                        delegate: Item {
                            id: cell
                            required property var modelData
                            required property int index
                            width: col.width / 7
                            height: col.width / 7
                            readonly property bool isToday: win.showsThisMonth && modelData === win.today.getDate()
                            readonly property bool weekend: (index % 7) >= 5

                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(cell.width, cell.height) - 4
                                height: width
                                radius: width / 2
                                color: cell.isToday ? Theme.base0D : "transparent"
                                visible: cell.modelData > 0
                                Text {
                                    anchors.centerIn: parent
                                    text: cell.modelData > 0 ? cell.modelData : ""
                                    color: cell.isToday ? Theme.base00
                                        : (cell.weekend ? Theme.base08 : Theme.base05)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 2
                                    font.features: ({ "tnum": 1 })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
