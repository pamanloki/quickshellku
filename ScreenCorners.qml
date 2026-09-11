import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Rounded display corners (macOS-style): four tiny click-through surfaces, one
// per screen corner, each painting a black notch so the screen looks rounded.
// Static and tiny — negligible cost. Theme.screenCornerRadius = 0 disables.
Scope {
    component Corner: PanelWindow {
        id: cwin
        required property var modelData
        property string edge: "tl"     // tl | tr | bl | br
        screen: modelData

        readonly property int r: Theme.screenCornerRadius
        anchors {
            top: edge === "tl" || edge === "tr"
            bottom: edge === "bl" || edge === "br"
            left: edge === "tl" || edge === "bl"
            right: edge === "tr" || edge === "br"
        }
        implicitWidth: r
        implicitHeight: r
        color: "transparent"
        visible: r > 0
        mask: Region {}
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:corner"

        Canvas {
            anchors.fill: parent
            onPaint: {
                const R = width;
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = "#000000";
                ctx.fillRect(0, 0, R, R);
                // clear the quarter disc centred on the inner corner
                const cx = (cwin.edge === "tl" || cwin.edge === "bl") ? R : 0;
                const cy = (cwin.edge === "tl" || cwin.edge === "tr") ? R : 0;
                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                ctx.arc(cx, cy, R, 0, 2 * Math.PI);
                ctx.fill();
            }
            Component.onCompleted: requestPaint()
        }
    }

    Variants { model: Quickshell.screens; Corner { edge: "tl" } }
    Variants { model: Quickshell.screens; Corner { edge: "tr" } }
    Variants { model: Quickshell.screens; Corner { edge: "bl" } }
    Variants { model: Quickshell.screens; Corner { edge: "br" } }
}
