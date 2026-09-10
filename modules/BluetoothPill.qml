import QtQuick
import Quickshell
import "root:/services"

// bluetooth equivalent (bluez). Left click opens the native BT panel;
// right click opens bluetui.
StatPill {
    id: root
    icon: Bluetooth.icon
    value: {
        if (!Bluetooth.powered)
            return "off";
        for (const d of Bluetooth.devices)
            if (d.connected)
                return d.name;
        return "on";
    }
    accent: !Bluetooth.powered ? Theme.base08
        : (Bluetooth.anyConnected ? Theme.base0B : Theme.base05)
    iconBg: Theme.base03

    onClicked: Globals.toggleBluetooth()
    onRightClicked: Quickshell.execDetached(["footx", "-f", "-e", "bluetui"])
}
