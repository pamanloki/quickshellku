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
    }

    // ---------------- Right ----------------
    Row {
        id: rightRow
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.pillGap

        StatCapsule {}
        BatteryPill {}
        QuickSettingsButton {}
        Clock {}
        Tray {}
        PowerButton {}
    }
}
