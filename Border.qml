import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "root:/services"

// caelestia-style screen border. Two jobs, per monitor:
//   1. Thin, click-through layer surfaces reserve `borderThickness` px on the
//      top/left/right edges (the bar reserves the bottom itself), so tiled
//      windows inset away from the screen edge — the same exclusion-zone trick
//      as caelestia's modules/drawers/Exclusions.qml.
//   2. One full-screen overlay paints a `borderColor` frame with rounded TOP
//      corners over that margin. The frame is OPEN at the bottom: its sides run
//      straight down into the bar, so (with borderColor == the bar colour) the
//      border and the bar read as one continuous surface — the same trick
//      IslandBg uses for the panels. The overlay must IGNORE other surfaces'
//      exclusive zones (ExclusionMode.Ignore) or the compositor shrinks it to
//      the inner area and the margin shows the bare compositor backdrop instead.
// The overlay's input region is empty, so it never eats clicks. Set
// Theme.borderThickness to 0 to turn the whole thing off.
Scope {
    // ---- edge exclusion zones (reserve the top/side margins) ----
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

    // ---- decorative frame overlay ----
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            visible: Theme.borderThickness > 0
            mask: Region {}                       // fully click-through
            exclusionMode: ExclusionMode.Ignore   // span the whole output
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell:border"

            readonly property real t: Theme.borderThickness
            // desktop area sits above the bar; the frame is open at the bottom
            // so it flows into the bar.
            readonly property real outerH: height - Theme.barHeight
            readonly property real innerW: width - 2 * t
            readonly property real innerH: outerH - t
            readonly property real r: Math.max(0, Math.min(Theme.borderRounding,
                Math.min(innerW, innerH) / 2))

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                antialiasing: true

                // Outer rectangle (down to the bar) minus an inner rect with
                // rounded TOP corners and an open bottom (odd-even fill). Only
                // the top + side margins are painted; the sides run down to the
                // bar so the frame and bar merge.
                ShapePath {
                    fillColor: Theme.borderColor
                    strokeWidth: 0
                    fillRule: ShapePath.OddEvenFill

                    // outer rect (whole desktop area, above the bar)
                    startX: 0; startY: 0
                    PathLine { x: win.width; y: 0 }
                    PathLine { x: win.width; y: win.outerH }
                    PathLine { x: 0; y: win.outerH }
                    PathLine { x: 0; y: 0 }

                    // inner cut-out: rounded top corners, square open bottom
                    PathMove { x: win.t + win.r; y: win.t }
                    PathLine { x: win.width - win.t - win.r; y: win.t }
                    PathArc { x: win.width - win.t; y: win.t + win.r; radiusX: win.r; radiusY: win.r }
                    PathLine { x: win.width - win.t; y: win.outerH }
                    PathLine { x: win.t; y: win.outerH }
                    PathLine { x: win.t; y: win.t + win.r }
                    PathArc { x: win.t + win.r; y: win.t; radiusX: win.r; radiusY: win.r }
                }
            }
        }
    }
}
