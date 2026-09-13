import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// macOS-style hot corners. Only tiny corner regions are input-masked, so the
// rest of the screen stays click-through. A short dwell avoids accidental
// triggers, and each corner re-arms only after the cursor leaves it.
//   bottom-left  → Launchpad
//   bottom-right → Control Centre
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:hotcorners"

        // only the corner squares are interactive; everything else is passthrough
        mask: Region {
            Region { item: bl }
            Region { item: br }
        }

        readonly property int sz: 6

        component Corner: Item {
            id: corner
            width: win.sz
            height: win.sz
            property var action
            property bool armed: true
            HoverHandler {
                onHoveredChanged: {
                    if (hovered) {
                        if (corner.armed) dwell.restart();
                    } else {
                        dwell.stop();
                        corner.armed = true;
                    }
                }
            }
            Timer {
                id: dwell
                interval: 130
                onTriggered: {
                    corner.armed = false;       // don't retrigger until cursor leaves
                    if (corner.action) corner.action();
                }
            }
        }

        Corner {
            id: bl
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            action: () => Globals.toggleLauncher()
        }
        Corner {
            id: br
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            action: () => Globals.toggleQuickSettings()
        }
    }
}
