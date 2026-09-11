import QtQuick
import QtQuick.Shapes
import "root:/services"

// Panel background that merges into the bar: rounded TOP corners, straight
// sides, and an OPEN bottom (no bottom edge/border) so it joins the bar as one
// surface. The border is drawn on top + both sides, down to the bar.
Shape {
    id: root
    property real radius: 12
    property color fill: Theme.base00
    property color stroke: Theme.base02
    property real strokeWidth: 1
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true

    ShapePath {
        id: sp
        property real sw: root.strokeWidth
        fillColor: root.fill
        strokeColor: root.stroke
        strokeWidth: root.strokeWidth
        capStyle: ShapePath.FlatCap
        joinStyle: ShapePath.RoundJoin

        // bottom-left -> up left -> round top-left -> top -> round top-right ->
        // down right -> bottom-right. Bottom edge left open; fill closes it.
        startX: sp.sw / 2
        startY: root.height
        PathLine { x: sp.sw / 2; y: root.radius }
        PathArc {
            x: root.radius; y: sp.sw / 2
            radiusX: root.radius; radiusY: root.radius
        }
        PathLine { x: root.width - root.radius; y: sp.sw / 2 }
        PathArc {
            x: root.width - sp.sw / 2; y: root.radius
            radiusX: root.radius; radiusY: root.radius
        }
        PathLine { x: root.width - sp.sw / 2; y: root.height }
    }
}
