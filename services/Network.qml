pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// WiFi status + management via iwd (`iwctl`), matching your impala/iwd setup.
// Status polling is robust; the network list parses iwctl output best-effort.
// The WiFi panel always offers "Manage in impala" as a reliable fallback.
Singleton {
    id: root

    property string device: ""        // e.g. wlan0
    property string state: "unknown"  // connected / disconnected / ...
    property string ssid: ""
    property int signalStrength: 0            // 0..100 (best-effort)
    property bool radioOn: true

    readonly property bool connected: state === "connected"

    // Network list for the panel: [{ssid, security, connected}]
    property var networks: []
    property bool scanning: false

    readonly property string icon: !radioOn ? "󰤮"
        : connected ? (signalStrength >= 75 ? "󰤨" : signalStrength >= 50 ? "󰤥" : signalStrength >= 25 ? "󰤢" : "󰤟")
        : "󰤭"

    function _stripAnsi(s) {
        // Remove ANSI colour codes and box-drawing padding iwctl loves to add.
        return s.replace(/\x1b\[[0-9;]*m/g, "");
    }

    function refresh() {
        rfState.running = true;
        if (!device) {
            devProc.running = true;
            return;
        }
        showProc.running = true;
    }

    function scan() {
        if (!device)
            return;
        root.scanning = true;
        scanProc.command = ["iwctl", "station", device, "scan"];
        scanProc.running = true;
    }

    function _loadNetworks() {
        if (!device)
            return;
        netProc.command = ["sh", "-c", "iwctl station " + device + " get-networks"];
        netProc.running = true;
    }

    // Connect. passphrase may be empty for known networks.
    function connect(ssid, passphrase) {
        if (!device)
            return;
        if (passphrase && passphrase.length > 0)
            connProc.command = ["iwctl", "--passphrase", passphrase, "station", device, "connect", ssid];
        else
            connProc.command = ["iwctl", "station", device, "connect", ssid];
        connProc.running = true;
    }

    function disconnect() {
        if (!device)
            return;
        connProc.command = ["iwctl", "station", device, "disconnect"];
        connProc.running = true;
    }

    function setRadio(on) {
        // rfkill is the most reliable cross-tool toggle.
        rfkillProc.command = ["rfkill", on ? "unblock" : "block", "wifi"];
        rfkillProc.running = true;
    }

    // Discover the first wifi station device.
    Process {
        id: devProc
        command: ["sh", "-c", "iwctl device list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = root._stripAnsi(text).split("\n");
                for (const l of lines) {
                    // Prefer explicit station rows.
                    if (/station/i.test(l)) {
                        const parts = l.trim().split(/\s+/);
                        if (parts.length && parts[0] && !/^-+$/.test(parts[0])) {
                            root.device = parts[0];
                            break;
                        }
                    }
                }
                if (root.device)
                    root.refresh();
            }
        }
    }

    Process {
        id: showProc
        command: ["sh", "-c", "iwctl station " + root.device + " show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = root._stripAnsi(text);
                const st = (/State\s+(\S+)/.exec(t) || [])[1];
                const net = (/Connected network\s+(.+)/.exec(t) || [])[1];
                root.state = st ? st.toLowerCase() : "disconnected";
                root.ssid = net ? net.trim() : "";
                // iwctl reports RSSI in centi-dBm under "RSSI"; map roughly to %.
                const rssi = (/RSSI\s+(-?\d+)/.exec(t) || [])[1];
                if (rssi) {
                    const dbm = parseInt(rssi) / 100.0;
                    root.signalStrength = Math.max(0, Math.min(100, Math.round(2 * (dbm + 100))));
                }
            }
        }
    }

    Process {
        id: netProc
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = root._stripAnsi(text).split("\n");
                const out = [];
                for (let l of lines) {
                    const raw = l;
                    l = l.trim();
                    if (!l || /Available networks/i.test(l) || /Network name/i.test(l) || /^-+/.test(l))
                        continue;
                    // A leading '>' marks the currently connected network.
                    const isConn = /^>/.test(l);
                    l = l.replace(/^>\s*/, "");
                    // Trailing tokens are security + signal bars; SSID may contain
                    // spaces, so peel known security keywords from the right.
                    const parts = l.split(/\s{2,}/).filter(x => x.length);
                    if (!parts.length)
                        continue;
                    let ssid = parts[0];
                    let security = parts.length > 1 ? parts[1] : "";
                    if (ssid)
                        out.push({ ssid: ssid, security: security, connected: isConn });
                }
                root.networks = out;
                root.scanning = false;
            }
        }
    }

    Process {
        id: scanProc
        onExited: {
            // Give iwd a moment to populate results, then list them.
            scanDelay.start();
        }
    }
    Timer {
        id: scanDelay
        interval: 1500
        onTriggered: root._loadNetworks()
    }

    Process { id: connProc; onExited: root.refresh() }
    Process { id: rfkillProc; onExited: root.refresh() }

    Process {
        id: rfState
        command: ["sh", "-c", "rfkill list wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                // radio is on only when neither soft- nor hard-blocked
                root.radioOn = !/blocked:\s+yes/i.test(text);
            }
        }
    }

    // Wi-Fi state changes slowly; user actions refresh immediately via each
    // Process.onExited, so 10s (was 5s) halves the rfkill + iwctl background
    // spawns with no practical loss of freshness on the bar.
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
