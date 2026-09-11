import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// macOS-style Dock: floating rounded bar, bottom centre. A Launchpad button,
// then pinned + running apps (grouped from niri windows) — hover magnify, name
// tooltip, running dot. Click focuses a running app or launches a pinned one.
PanelWindow {
    id: dock
    required property var modelData
    screen: modelData

    // Pinned app ids (edit to taste; matches .desktop / window app_id).
    property var pinned: ["brave", "foot"]

    anchors { bottom: true }
    margins.bottom: 6
    implicitWidth: Math.max(1, dockBg.width)
    implicitHeight: Theme.dockIconSize + 22 + 42   // extra top for tooltip + magnify
    exclusiveZone: Theme.dockIconSize + 22 + 6
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:dock"

    function _norm(s) { return (s || "").toLowerCase().replace(/[^a-z0-9]/g, ""); }

    // pinned apps that aren't running (as launchers), then EVERY open window
    // (one icon per window, so 2 foot windows show 2 icons).
    readonly property var items: {
        const list = Niri.windowList || [];
        const runningNorms = ({});
        for (let i = 0; i < list.length; i++)
            runningNorms[dock._norm(list[i].app_id || "?")] = true;

        const out = [];
        for (const p of dock.pinned) {
            const pn = dock._norm(p);
            let running = false;
            for (const n in runningNorms)
                if (n === pn || n.indexOf(pn) === 0 || pn.indexOf(n) === 0) { running = true; break; }
            if (!running) out.push({ app_id: p, id: -1, running: false });
        }
        for (let i = 0; i < list.length; i++)
            out.push({ app_id: list[i].app_id || "?", id: list[i].id, running: true });
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
    function launch(appId) {
        let entry = DesktopEntries.byId(appId);
        if (!entry) { try { entry = DesktopEntries.heuristicLookup(appId); } catch (e) {} }
        if (entry) entry.execute();
    }

    component DockCell: Item {
        id: cell
        property string source: ""
        property string glyph: ""      // draw a coloured tile instead of an image
        property color glyphBg: Theme.base0D
        property string tip: ""
        property bool running: false
        signal activated()
        implicitWidth: Theme.dockIconSize + 10
        implicitHeight: Theme.dockIconSize + 22   // = dock background height

        Rectangle {   // tooltip (floats above the cell, into the headroom)
            visible: cellMA.containsMouse && cell.tip.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 8
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

        Item {
            id: iconWrap
            width: Theme.dockIconSize
            height: Theme.dockIconSize
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 9
            transformOrigin: Item.Bottom
            scale: cellMA.containsMouse ? 1.35 : 1
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            Image {
                anchors.fill: parent
                visible: cell.glyph.length === 0
                sourceSize.width: Theme.dockIconSize
                sourceSize.height: Theme.dockIconSize
                source: cell.source
                fillMode: Image.PreserveAspectFit
            }
            Rectangle {
                anchors.fill: parent
                visible: cell.glyph.length > 0
                radius: 10
                color: cell.glyphBg
                Text {
                    anchors.centerIn: parent
                    text: cell.glyph
                    color: Theme.base00
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: Theme.dockIconSize * 0.6
                }
            }
        }

        Rectangle {
            visible: cell.running
            width: 4; height: 4; radius: 2
            color: Theme.base05
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
        }

        MouseArea { id: cellMA; anchors.fill: parent; hoverEnabled: true; onClicked: cell.activated() }
    }

    Rectangle {
        id: dockBg
        height: Theme.dockIconSize + 22
        width: dockRow.implicitWidth + 18
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        radius: 22
        color: Theme.base01
        border.width: 1
        border.color: Theme.base02

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 4

            DockCell {
                glyph: "󰀻"
                glyphBg: Theme.base0D
                tip: "Launcher"
                onActivated: Globals.toggleLauncher()
            }

            Rectangle {
                width: 1; height: Theme.dockIconSize * 0.7
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.base03
                visible: dock.items.length > 0
            }

            Repeater {
                model: dock.items
                delegate: DockCell {
                    required property var modelData
                    source: dock.iconFor(modelData.app_id)
                    tip: dock.labelFor(modelData.app_id)
                    running: modelData.running
                    onActivated: {
                        if (modelData.id >= 0) Niri.focusWindow(modelData.id);
                        else dock.launch(modelData.app_id);
                    }
                }
            }
        }
    }
}
