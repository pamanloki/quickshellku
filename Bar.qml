import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"
import "root:/modules"

// The bar: a faithful Quickshell port of your bottom Waybar dock.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors {
        left: true
        right: true
        bottom: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.base00

    // Sit below fullscreen windows but reserve space (exclusive dock).
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:bar"

    // ---------------- Left ----------------
    Row {
        id: leftRow
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.pillGap

        MenuButton {}
        Workspaces {}
        Separator {}
        Taskbar {}
        Separator { visible: Niri.windowList.length > 0 }
        WindowTitle {}
    }

    // ---------------- Right ----------------
    Row {
        id: rightRow
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.pillGap

        StatPill {
            icon: ""
            value: SystemStats.cpuPercent + "%"
            accent: Theme.base08
        }
        StatPill {
            icon: ""
            value: SystemStats.memUsedGiB.toFixed(1) + "GiB"
            accent: Theme.base0C
            onClicked: Quickshell.execDetached(["footx", "-e", "-f", "btop"])
        }
        StatPill {
            icon: ""
            value: SystemStats.diskFree
            accent: Theme.base0A
        }
        TempPill {}
        BacklightPill {}
        VolumePill {}
        XbpsPill {}
        Clock {}
        BluetoothPill {}
        NetworkPill {}
        Tray {}
        PowerButton {}
    }
}
