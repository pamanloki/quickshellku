pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Bluetooth via `bluetoothctl` (bluez), matching your bluetui setup.
//
// Anti-flicker: refresh() runs every few seconds. It must NOT expose transient
// states, or the bar pill's value flips width ("on" -> "BLAST") each cycle and
// the right-anchored row reflows, making the clock jump. So we build the whole
// device list (enriched with connected/paired) into a pending array and assign
// `devices` exactly once, and only when a signature of the visible fields
// actually changed. Same for `powered`.
Singleton {
    id: root

    property bool powered: false
    property var devices: []          // [{mac, name, connected, paired}]
    property bool scanning: false

    property string _sig: ""
    property var _pending: []
    property int _enrichIndex: 0

    readonly property bool anyConnected: {
        for (const d of devices)
            if (d.connected)
                return true;
        return false;
    }

    readonly property string icon: !powered ? "󰂲" : (anyConnected ? "󰂱" : "󰂯")

    // First connected device's name, or "" — used by the bar pill. Stable name
    // so the pill width doesn't change between refreshes.
    readonly property string connectedName: {
        for (const d of devices)
            if (d.connected)
                return d.name;
        return "";
    }

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

    function _applyDevices(list) {
        let sig = "";
        for (let i = 0; i < list.length; i++)
            sig += list[i].mac + ":" + list[i].name + ":" + list[i].connected + ":" + list[i].paired + "|";
        if (sig === root._sig)
            return;               // nothing visible changed -> don't churn bindings
        root._sig = sig;
        root.devices = list;
    }

    Process {
        id: showProc
        command: ["sh", "-c", "bluetoothctl show"]
        stdout: StdioCollector {
            onStreamFinished: root.powered = /Powered:\s+yes/i.test(text)
        }
    }

    // List devices, then enrich each into _pending; assign once when done.
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
                root._pending = out;
                root._enrichIndex = 0;
                if (out.length === 0)
                    root._applyDevices([]);
                else
                    root._enrichNext();
            }
        }
    }

    function _enrichNext() {
        if (_enrichIndex >= _pending.length) {
            _applyDevices(_pending.slice());
            return;
        }
        infoProc.command = ["sh", "-c", "bluetoothctl info " + _pending[_enrichIndex].mac];
        infoProc.running = true;
    }

    Process {
        id: infoProc
        stdout: StdioCollector {
            onStreamFinished: {
                const d = root._pending[root._enrichIndex];
                if (d) {
                    d.connected = /Connected:\s+yes/i.test(text);
                    d.paired = /Paired:\s+yes/i.test(text);
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
