import QtQuick
import "root:/services"

// The "custom/sep" module from your Waybar.
Item {
    implicitWidth: label.implicitWidth + 8
    implicitHeight: Theme.barHeight
    Text {
        id: label
        anchors.centerIn: parent
        text: ""
        color: Theme.base03
        font.family: Theme.fontFamilyFallback
        font.pixelSize: 18
    }
}
