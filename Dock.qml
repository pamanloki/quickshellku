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

    // parabolic magnify state (cursor x within the dock row)
    property real hoverX: -1
    property bool dockHovering: false
    readonly property real magRadius: 110   // influence distance
    readonly property real magBoost: 0.6    // peak extra scale at the cursor

    anchors { bottom: true }
    margins.bottom: 6
    implicitWidth: Math.max(1, dockBg.width)
    implicitHeight: Theme.dockIconSize + 22 + 42   // extra top for tooltip + magnify
    exclusiveZone: Theme.dockIconSize + 22 + 6
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:dock"

    function _norm(s) { return (s || "").toLowerCase().replace(/[^a-z0-9]/g, ""); }

    // macOS-style: one icon per app. Pinned first (matched to running so they
    // don't double up), then any other running apps.
    readonly property var items: {
        const list = Niri.windowList || [];
        const groups = ({});
        const order = [];
        for (let i = 0; i < list.length; i++) {
            const n = dock._norm(list[i].app_id || "?");
            if (!(n in groups)) { groups[n] = { app_id: list[i].app_id || "?", norm: n, count: 0 }; order.push(n); }
            groups[n].count++;
        }
        const out = [];
        const used = ({});
        for (const p of dock.pinned) {
            const pn = dock._norm(p);
            let m = null;
            for (const n in groups)
                if (n === pn || n.indexOf(pn) === 0 || pn.indexOf(n) === 0) { m = n; break; }
            if (m) { out.push({ app_id: groups[m].app_id, norm: m, running: true, count: groups[m].count }); used[m] = true; }
            else { out.push({ app_id: p, norm: pn, running: false, count: 0 }); }
        }
        for (const n of order)
            if (!used[n]) out.push({ app_id: groups[n].app_id, norm: n, running: true, count: groups[n].count });
        return out;
    }

    // window ids of a given app (normalized), in order
    function windowsOf(norm) {
        const list = Niri.windowList || [];
        const ids = [];
        for (let i = 0; i < list.length; i++)
            if (dock._norm(list[i].app_id || "?") === norm) ids.push(list[i].id);
        return ids;
    }
    // click a running app: focus its next window (cycle through them)
    function activateApp(norm) {
        const ids = windowsOf(norm);
        if (ids.length === 0) return;
        const idx = ids.indexOf(Niri.focusedWindowId);
        Niri.focusWindow(ids[(idx + 1) % ids.length]);
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
        property int count: 0
        signal activated()
        signal menuRequested()
        implicitWidth: Theme.dockIconSize + 10
        implicitHeight: Theme.dockIconSize + 22   // = dock background height

        // parabolic magnification based on cursor distance
        readonly property real _mag: {
            if (!dock.dockHovering) return 1;
            const d = Math.abs((x + width / 2) - dock.hoverX);
            if (d >= dock.magRadius) return 1;
            const t = 1 - d / dock.magRadius;
            return 1 + dock.magBoost * t * t;
        }

        Rectangle {   // tooltip (floats above the cell, into the headroom)
            visible: cellMA.containsMouse && cell.tip.length > 0 && !Globals.dockMenuOpen
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
            scale: cell._mag
            Behavior on scale { enabled: !dock.dockHovering; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

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

        Row {
            visible: cell.running
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
            spacing: 3
            Repeater {
                model: Math.min(cell.count, 3)
                delegate: Rectangle { width: 4; height: 4; radius: 2; color: Theme.base05 }
            }
        }

        MouseArea {
            id: cellMA
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => mouse.button === Qt.RightButton ? cell.menuRequested() : cell.activated()
        }
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

            HoverHandler {
                id: rowHover
                onPointChanged: dock.hoverX = point.position.x
                onHoveredChanged: dock.dockHovering = hovered
            }

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
                    id: dcell
                    required property var modelData
                    source: dock.iconFor(modelData.app_id)
                    tip: dock.labelFor(modelData.app_id)
                    running: modelData.running
                    count: modelData.count
                    onActivated: {
                        if (modelData.running) dock.activateApp(modelData.norm);
                        else dock.launch(modelData.app_id);
                    }
                    onMenuRequested: {
                        if (!modelData.running) return;
                        const list = Niri.windowList || [];
                        const wins = [];
                        for (let i = 0; i < list.length; i++)
                            if (dock._norm(list[i].app_id || "?") === modelData.norm)
                                wins.push({ id: list[i].id, icon: dock.iconFor(list[i].app_id), title: (list[i].title && list[i].title.length ? list[i].title : dock.labelFor(list[i].app_id)) });
                        // dock window is centred, so add its on-screen left edge
                        const cx = (dock.screen.width - dock.width) / 2 + dcell.mapToItem(null, dcell.width / 2, 0).x;
                        Globals.openDockMenu(wins, cx);
                    }
                }
            }
        }
    }
}
