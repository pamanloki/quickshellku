import QtQuick
import Quickshell
import "root:/services"

// backlight equivalent. Scroll changes brightness via `light`; left click
// opens your nightlight menu (matches Waybar on-click); the OSD shows on change.
StatPill {
    id: root
    icon: Brightness.icon
    value: Brightness.percent + "%"
    valueMax: "100%"
    accent: Theme.base0E

    onClicked: Quickshell.execDetached(["nightlight-fuzzel"])
    onScrollUp: { Brightness.raise(); Globals.showBrightnessOsd(); }
    onScrollDown: { Brightness.lower(); Globals.showBrightnessOsd(); }
}
