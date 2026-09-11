import QtQuick
import Quickshell
import "root:/services"

// network equivalent (iwd). Icon reflects connection + signal.
// Left click opens the native WiFi panel; right click opens impala.
StatPill {
    id: root
    icon: Network.icon
    // SSID only in the bar (the live % updates every few seconds and its
    // changing digit-count would reflow the whole right side); full signal %
    // is shown in the Wi-Fi panel.
    value: Network.connected ? Network.ssid : "off"
    accent: Network.connected ? Theme.base0A : Theme.base08
    iconBg: Theme.base03

    onClicked: Globals.toggleWifi()
    onRightClicked: Quickshell.execDetached(["footx", "-e", "-f", "impala"])
}
