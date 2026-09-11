import QtQuick
import Quickshell
import "root:/services"

// custom/temp-icon + custom/temp equivalent. Colour tracks cool/warm/critical.
StatPill {
    id: root
    icon: SystemStats.tempClass === "critical" ? "󰸁"
        : (SystemStats.tempClass === "warm" ? "󱃂" : "󰔏")
    value: SystemStats.tempKnown ? (SystemStats.tempC + "°C") : "N/A"
    valueMax: "100°C"
    accent: SystemStats.tempClass === "critical" ? Theme.base08
        : SystemStats.tempClass === "warm" ? Theme.base0A
        : SystemStats.tempClass === "unknown" ? Theme.base03
        : Theme.base0B

    onClicked: Quickshell.execDetached(["footx", "-e", "-f", "btop"])
}
