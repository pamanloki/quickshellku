import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// macOS-style top menu bar: Apple menu + focused app name on the left, status
// items (search, network, bluetooth, volume, control centre, clock,
// notifications) on the right.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.menuBarHeight
    color: Theme.base00

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:menubar"

    // status item: icon (+ optional label), hover highlight, click.
    component Item2: Rectangle {
        id: it
        property string icon: ""
        property string label: ""
        property color iconColor: Theme.base05
        signal clicked()
        implicitWidth: row.implicitWidth + 14
        implicitHeight: Theme.menuBarHeight - 6
        radius: 6
        color: ma.containsMouse ? Theme.base02 : "transparent"
        anchors.verticalCenter: parent.verticalCenter
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 5
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: it.icon
                color: it.iconColor
                font.family: Theme.fontFamilyFallback
                font.pixelSize: Theme.fontSize
                visible: text.length > 0
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: it.label
                color: Theme.base05
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                font.weight: Theme.fontWeight
                visible: text.length > 0
            }
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: it.clicked() }
    }

    // ---------------- Left: apple + app name ----------------
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Item2 {
            icon: ""
            iconColor: Theme.base05
            onClicked: Globals.togglePower()
        }
        Item2 {
            label: {
                const id = Niri.focusedAppId;
                if (!id) return "Desktop";
                return id.charAt(0).toUpperCase() + id.slice(1);
            }
            onClicked: Globals.toggleLauncher()
        }
    }

    // ---------------- Right: status cluster ----------------
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Item2 {
            icon: ""
            onClicked: Globals.toggleLauncher()
        }
        Item2 {
            icon: Network.icon
            iconColor: Network.connected ? Theme.base05 : Theme.base03
            onClicked: Globals.toggleWifi()
        }
        Item2 {
            icon: Bluetooth.icon
            iconColor: Bluetooth.powered ? Theme.base05 : Theme.base03
            onClicked: Globals.toggleBluetooth()
        }
        Item2 {
            icon: Audio.muted || Audio.volume === 0 ? "󰖁" : (Audio.volume >= 50 ? "󰕾" : "󰖀")
            onClicked: Globals.toggleQuickSettings()
        }
        Item2 {
            icon: "󰕮"
            onClicked: Globals.toggleQuickSettings()
        }
        Item2 {
            label: Qt.formatDateTime(Time.now, "ddd d MMM  HH:mm")
            onClicked: Globals.toggleCalendar()
        }
        Item2 {
            icon: Notifications.doNotDisturb ? "󰂛" : "󰂚"
            iconColor: Notifications.unread > 0 ? Theme.base0A : Theme.base05
            onClicked: Globals.toggleNotifs()
        }
    }
}
