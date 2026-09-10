import QtQuick
import "root:/services"

// niri/window equivalent: "~> {title}" with a few rewrites.
Item {
    id: root
    implicitWidth: Math.min(label.implicitWidth, 700)
    implicitHeight: Theme.barHeight

    function rewrite(t) {
        if (!t || t.length === 0)
            return "Desktop";
        if (t === "Firefox Web Browser")
            return "Firefox";
        if (t === "mpv Media Player")
            return "mpv";
        return t;
    }

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 4
        width: root.width - 4
        elide: Text.ElideRight
        text: "~> " + root.rewrite(Niri.focusedTitle)
        color: Theme.base05
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
    }
}
