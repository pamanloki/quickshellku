import QtQuick
import Quickshell
import "root:/services"

// network equivalent (iwd). Icon reflects connection + signal.
// Left click opens the native WiFi panel; right click opens impala.
StatPill {
    id: root
    icon: Network.icon
    value: Network.connected
        ? (Network.ssid + (Network.signalStrength > 0 ? " (" + Network.signalStrength + "%)" : ""))
        : "off"
    accent: Network.connected ? Theme.base0A : Theme.base08
    iconBg: Theme.base03

    onClicked: Globals.toggleWifi()
    onRightClicked: Quickshell.execDetached(["footx", "-e", "-f", "impala"])
}
