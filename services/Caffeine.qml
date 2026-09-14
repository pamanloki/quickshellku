pragma Singleton

import Quickshell
import QtQuick

// "Keep Awake" (macOS Amphetamine-style). Holds a Wayland idle-inhibitor while
// active so the screen won't blank / the system won't idle-sleep. Uses the
// standalone `wlinhibit` helper (wlroots idle-inhibit); install it if missing.
//   Void:  xbps-install wlinhibit   (or build from https://github.com/tim-hilt/wlinhibit)
Singleton {
    id: root

    property bool active: false

    function toggle() { active = !active; _apply(); }
    function _apply() {
        if (active)
            Quickshell.execDetached(["sh", "-c", "pkill -x wlinhibit 2>/dev/null; exec wlinhibit"]);
        else
            Quickshell.execDetached(["pkill", "-x", "wlinhibit"]);
    }

    // don't leave a stray inhibitor running from a previous session
    Component.onCompleted: Quickshell.execDetached(["pkill", "-x", "wlinhibit"])
}
