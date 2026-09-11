import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "root:/services"

// caelestia-style screen border. Two jobs, per monitor:
//   1. Four thin, click-through layer surfaces reserve `borderThickness` px on
//      each edge (exclusive zones), so tiled windows inset away from the edge —
//      the same trick caelestia uses in modules/drawers/Exclusions.qml.
//   2. One decorative full-screen overlay paints a `base00` frame with rounded
//      inner corners over that reserved margin, so the wallpaper (and maximised
//      windows) get a clean inset with rounded corners instead of bleeding to
//      the edge.
// The overlay's input region is empty, so it never eats clicks. Set
// Theme.borderThickness to 0 to turn the whole thing off.
Scope {
    // ---- edge exclusion zones (reserve the margin) ----
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: Theme.borderThickness
            exclusiveZone: Theme.borderThickness
            visible: Theme.borderThickness > 0
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:border-x"
        }
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { left: true; top: true; bottom: true }
            implicitWidth: Theme.borderThickness
            exclusiveZone: Theme.borderThickness
            visible: Theme.borderThickness > 0
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:border-x"
        }
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { right: true; top: true; bottom: true }
            implicitWidth: Theme.borderThickness
            exclusiveZone: Theme.borderThickness
            visible: Theme.borderThickness > 0
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:border-x"
        }
    }
    // Bottom gap sits *above* the bar (the bar reserves its own height), so the
    // desktop floats off the bar too.
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { bottom: true; left: true; right: true }
            implicitHeight: Theme.borderThickness
            exclusiveZone: Theme.borderThickness
            visible: Theme.borderThickness > 0
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:border-x"
        }
    }

    // ---- decorative frame overlay ----
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusiveZone: 0
            visible: Theme.borderThickness > 0
            mask: Region {}   // fully click-through — purely decorative
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell:border"

            readonly property real t: Theme.borderThickness
            // area the desktop occupies (above the bar)
            readonly property real outerH: height - Theme.barHeight
            readonly property real innerW: width - 2 * t
            readonly property real innerH: outerH - 2 * t
            readonly property real r: Math.max(0, Math.min(Theme.borderRounding,
                Math.min(innerW, innerH) / 2))

            Shape {
                width: win.width
                height: win.outerH
                preferredRendererType: Shape.CurveRenderer
                antialiasing: true

                // Outer rectangle minus an inner rounded rectangle (odd-even
                // fill) leaves just the frame ring, filling only the reserved
                // margin — no window pixels are covered.
                ShapePath {
                    fillColor: Theme.base00
                    strokeWidth: 0
                    fillRule: ShapePath.OddEvenFill

                    // outer rect (whole desktop area, above the bar)
                    startX: 0; startY: 0
                    PathLine { x: win.width; y: 0 }
                    PathLine { x: win.width; y: win.outerH }
                    PathLine { x: 0; y: win.outerH }
                    PathLine { x: 0; y: 0 }

                    // inner rounded rect (the hole)
                    PathMove { x: win.t + win.r; y: win.t }
                    PathLine { x: win.width - win.t - win.r; y: win.t }
                    PathArc { x: win.width - win.t; y: win.t + win.r; radiusX: win.r; radiusY: win.r }
                    PathLine { x: win.width - win.t; y: win.outerH - win.t - win.r }
                    PathArc { x: win.width - win.t - win.r; y: win.outerH - win.t; radiusX: win.r; radiusY: win.r }
                    PathLine { x: win.t + win.r; y: win.outerH - win.t }
                    PathArc { x: win.t; y: win.outerH - win.t - win.r; radiusX: win.r; radiusY: win.r }
                    PathLine { x: win.t; y: win.t + win.r }
                    PathArc { x: win.t + win.r; y: win.t; radiusX: win.r; radiusY: win.r }
                }
            }
        }
    }
}
