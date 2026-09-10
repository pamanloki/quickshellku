import QtQuick
import Quickshell
import "root:/services"

// custom/xbps equivalent. Icon colour tracks state (updates/up-to-date/offline).
// Left click opens the upgrade script; right click re-checks.
StatPill {
    id: root
    icon: "󰏗"
    value: Xbps.state === "offline" ? "!" : String(Xbps.count)
    showValue: Xbps.count > 0 || Xbps.state === "offline"
    accent: Xbps.state === "offline" ? Theme.base08
        : (Xbps.state === "updates" ? Theme.base0B : Theme.base03)

    onClicked: Quickshell.execDetached(["footx", "-e", "-f", "xbps-upgrade.sh"])
    onRightClicked: Xbps.refresh()
}
