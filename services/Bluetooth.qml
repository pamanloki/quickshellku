pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Bluetooth via `bluetoothctl` (bluez), matching your bluetui setup.
// bluetoothctl output parses cleanly, so the native panel is reliable;
// the panel also offers "Manage in bluetui" as a fallback.
Singleton {
    id: root

    property bool powered: false
    property var devices: []          // [{mac, name, connected, paired}]
    property bool scanning: false

    readonly property bool anyConnected: {
        for (const d of devices)
            if (d.connected)
                return true;
        return false;
    }

    readonly property string icon: !powered ? "󰂲" : (anyConnected ? "󰂱" : "󰂯")

    function refresh() {
        showProc.running = true;
        devProc.running = true;
    }

    function setPowered(on) {
        powerProc.command = ["bluetoothctl", "power", on ? "on" : "off"];
        powerProc.running = true;
    }

    function toggleScan() {
        if (scanning) {
            scanOffProc.running = true;
            root.scanning = false;
        } else {
            scanOnProc.running = true;
            root.scanning = true;
        }
    }

    function connect(mac) {
        actProc.command = ["bluetoothctl", "connect", mac];
        actProc.running = true;
    }

    function disconnect(mac) {
        actProc.command = ["bluetoothctl", "disconnect", mac];
        actProc.running = true;
    }

    Process {
        id: showProc
        command: ["sh", "-c", "bluetoothctl show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.powered = /Powered:\s+yes/i.test(text);
            }
        }
    }

    // List devices, then enrich each with connected/paired via `info`.
    Process {
        id: devProc
        command: ["sh", "-c", "bluetoothctl devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const out = [];
                for (const l of lines) {
                    const m = l.match(/^Device\s+(\S+)\s+(.+)$/);
                    if (m)
                        out.push({ mac: m[1], name: m[2], connected: false, paired: false });
                }
                root.devices = out;
                root._enrichIndex = 0;
                root._enrichNext();
            }
        }
    }

    property int _enrichIndex: 0
    function _enrichNext() {
        if (_enrichIndex >= devices.length)
            return;
        infoProc.command = ["sh", "-c", "bluetoothctl info " + devices[_enrichIndex].mac];
        infoProc.running = true;
    }

    Process {
        id: infoProc
        stdout: StdioCollector {
            onStreamFinished: {
                const list = root.devices.slice();
                const d = list[root._enrichIndex];
                if (d) {
                    d.connected = /Connected:\s+yes/i.test(text);
                    d.paired = /Paired:\s+yes/i.test(text);
                    root.devices = list;
                }
                root._enrichIndex++;
                root._enrichNext();
            }
        }
    }

    Process { id: powerProc; onExited: root.refresh() }
    Process { id: scanOnProc; command: ["sh", "-c", "bluetoothctl --timeout 10 scan on"] }
    Process { id: scanOffProc; command: ["sh", "-c", "bluetoothctl scan off"] }
    Process { id: actProc; onExited: root.refresh() }

    Timer {
        interval: 6000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
