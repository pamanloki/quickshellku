import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// macOS-style Dock: a floating rounded bar at the bottom centre with a launcher
// button and one icon per running app (grouped from niri windows). Icons
// magnify on hover, show a running dot and a name tooltip; click focuses the app.
PanelWindow {
    id: dock
    required property var modelData
    screen: modelData

    anchors { bottom: true }
    margins.bottom: 6
    implicitWidth: Math.max(1, dockBg.width)
    // extra headroom above the bar for the hover tooltip
    implicitHeight: Theme.dockIconSize + 22 + 24
    exclusiveZone: Theme.dockIconSize + 22 + 6
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:dock"

    // one entry per app_id (first window becomes the focus target)
    readonly property var apps: {
        const list = Niri.windowList || [];
        const seen = ({});
        const out = [];
        for (let i = 0; i < list.length; i++) {
            const a = list[i].app_id || "?";
            if (!seen[a]) { seen[a] = true; out.push({ app_id: a, id: list[i].id }); }
        }
        return out;
    }

    function iconFor(appId) {
        if (!appId) return Quickshell.iconPath("application-x-executable");
        let entry = DesktopEntries.byId(appId);
        if (!entry) { try { entry = DesktopEntries.heuristicLookup(appId); } catch (e) {} }
        const name = entry && entry.icon ? entry.icon : appId;
        return Quickshell.iconPath(name, "application-x-executable");
    }
    function labelFor(appId) {
        if (!appId) return "";
        let entry = DesktopEntries.byId(appId);
        if (!entry) { try { entry = DesktopEntries.heuristicLookup(appId); } catch (e) {} }
        return entry && entry.name ? entry.name : appId;
    }

    component DockCell: Item {
        id: cell
        property string source: ""
        property string tip: ""
        property bool running: false
        signal activated()
        implicitWidth: Theme.dockIconSize + 8
        implicitHeight: dock.implicitHeight

        // hover tooltip
        Rectangle {
            visible: cellMA.containsMouse && cell.tip.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: tipText.implicitWidth + 16
            height: tipText.implicitHeight + 8
            radius: 6
            color: Theme.base01
            border.width: 1
            border.color: Theme.base02
            Text {
                id: tipText
                anchors.centerIn: parent
                text: cell.tip
                color: Theme.base05
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
            }
        }

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
        height: Theme.dockIconSize + 22
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

            DockCell {
                source: Quickshell.iconPath("view-app-grid-symbolic", "application-x-executable")
                tip: "Launcher"
                onActivated: Globals.toggleLauncher()
            }

            Rectangle {
                width: 1; height: Theme.dockIconSize * 0.7
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.base03
                visible: dock.apps.length > 0
            }

            Repeater {
                model: dock.apps
                delegate: DockCell {
                    required property var modelData
                    source: dock.iconFor(modelData.app_id)
                    tip: dock.labelFor(modelData.app_id)
                    running: true
                    onActivated: Niri.focusWindow(modelData.id)
                }
            }
        }
    }
}
