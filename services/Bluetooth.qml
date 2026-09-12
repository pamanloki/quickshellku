pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Bluetooth via `bluetoothctl` (bluez), matching your bluetui setup.
//
// Efficiency: the periodic poll used to spawn one `bluetoothctl info` process
// per device every few seconds. Now it uses bluez's `devices Connected` /
// `devices Paired` filters, so a full refresh is just four short commands total
// regardless of how many devices are paired — far fewer wakeups on battery.
//
// Anti-flicker: refresh() runs on a timer. It must NOT expose transient states,
// or the bar pill's value flips width ("on" -> "BLAST") each cycle and the
// right-anchored row reflows, making the clock jump. So we build the whole
// device list into a pending array and assign `devices` exactly once, and only
// when a signature of the visible fields actually changed. Same for `powered`.
Singleton {
    id: root

    property bool powered: false
    property var devices: []          // [{mac, name, connected, paired}]
    property bool scanning: false

    property string _sig: ""
    property var _all: []             // [{mac, name}] from `devices`
    property var _connected: ({})     // mac -> true
    property var _paired: ({})        // mac -> true

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
        devProc.running = true;   // chains: devices -> connected -> paired -> apply
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

    function _macsFrom(text) {
        const set = ({});
        const lines = text.split("\n");
        for (const l of lines) {
            const m = l.match(/^Device\s+(\S+)\s+/);
            if (m) set[m[1]] = true;
        }
        return set;
    }

    function _merge() {
        const out = [];
        for (let i = 0; i < root._all.length; i++) {
            const d = root._all[i];
            out.push({
                mac: d.mac,
                name: d.name,
                connected: root._connected[d.mac] === true,
                paired: root._paired[d.mac] === true
            });
        }
        _applyDevices(out);
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

    // All known devices, then the connected/paired subsets (one call each).
    Process {
        id: devProc
        command: ["sh", "-c", "bluetoothctl devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const l of text.split("\n")) {
                    const m = l.match(/^Device\s+(\S+)\s+(.+)$/);
                    if (m)
                        out.push({ mac: m[1], name: m[2] });
                }
                root._all = out;
                connProc.running = true;
            }
        }
    }
    Process {
        id: connProc
        command: ["sh", "-c", "bluetoothctl devices Connected 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root._connected = root._macsFrom(text);
                pairProc.running = true;
            }
        }
    }
    Process {
        id: pairProc
        command: ["sh", "-c", "bluetoothctl devices Paired 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root._paired = root._macsFrom(text);
                root._merge();
            }
        }
    }

    Process { id: powerProc; onExited: root.refresh() }
    // `--timeout 10` makes scan on exit by itself after 10s; clear the flag so
    // the panel button doesn't stay stuck on "Scanning…".
    Process { id: scanOnProc; command: ["sh", "-c", "bluetoothctl --timeout 10 scan on"]; onExited: { root.scanning = false; root.refresh(); } }
    Process { id: scanOffProc; command: ["sh", "-c", "bluetoothctl scan off"] }
    Process { id: actProc; onExited: root.refresh() }

    // User actions (connect/disconnect/power/scan) refresh immediately via each
    // Process.onExited, so this background poll only reconciles external changes
    // — 30s cuts the 4-`bluetoothctl`-per-cycle spawns to a third (was 10s).
    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
