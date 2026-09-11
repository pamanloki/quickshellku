import QtQuick
import "root:/services"

// backlight equivalent. Scroll changes brightness via `light`; left click
// opens the native night light panel; the OSD shows on brightness change.
StatPill {
    id: root
    icon: Brightness.icon
    value: Brightness.percent + "%"
    valueMax: "100%"
    accent: Theme.base0E

    onClicked: Globals.toggleNightlight()
    onScrollUp: Brightness.raise()
    onScrollDown: Brightness.lower()
}
