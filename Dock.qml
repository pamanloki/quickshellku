import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// macOS-style Dock: a floating rounded bar at the bottom centre with a launcher
// button and one icon per open window (from niri). Icons magnify on hover and
// show a running dot; click focuses the window.
PanelWindow {
    id: dock
    required property var modelData
    screen: modelData

    anchors { bottom: true }
    margins.bottom: 6
    implicitWidth: Math.max(1, dockBg.width)
    implicitHeight: Theme.dockIconSize + 22
    exclusiveZone: implicitHeight + 6
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:dock"

    function iconFor(appId) {
        if (!appId) return Quickshell.iconPath("application-x-executable");
        let entry = DesktopEntries.byId(appId);
        if (!entry) { try { entry = DesktopEntries.heuristicLookup(appId); } catch (e) {} }
        const name = entry && entry.icon ? entry.icon : appId;
        return Quickshell.iconPath(name, "application-x-executable");
    }

    // one dock cell: icon that magnifies on hover, optional running dot.
    component DockCell: Item {
        id: cell
        property string source: ""
        property bool running: false
        signal activated()
        implicitWidth: Theme.dockIconSize + 8
        implicitHeight: dock.implicitHeight

        Image {
            id: img
            width: Theme.dockIconSize
            height: Theme.dockIconSize
            sourceSize.width: Theme.dockIconSize
            sourceSize.height: Theme.dockIconSize
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            source: cell.source
            fillMode: Image.PreserveAspectFit
            transformOrigin: Item.Bottom
            scale: cellMA.containsMouse ? 1.35 : 1
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            visible: cell.running
            width: 4; height: 4; radius: 2
            color: Theme.base05
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
        }

        MouseArea { id: cellMA; anchors.fill: parent; hoverEnabled: true; onClicked: cell.activated() }
    }

    Rectangle {
        id: dockBg
        height: parent.height
        width: dockRow.implicitWidth + 16
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        radius: 20
        color: Theme.base01
        border.width: 1
        border.color: Theme.base02

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 2

            // launcher
            DockCell {
                source: Quickshell.iconPath("view-app-grid-symbolic", "application-x-executable")
                onActivated: Globals.toggleLauncher()
            }

            // separator
            Rectangle {
                width: 1; height: Theme.dockIconSize * 0.7
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.base03
                visible: Niri.windowList.length > 0
            }

            // open windows
            Repeater {
                model: Niri.windowList
                delegate: DockCell {
                    required property var modelData
                    source: dock.iconFor(modelData.app_id)
                    running: true
                    onActivated: Niri.focusWindow(modelData.id)
                }
            }
        }
    }
}
