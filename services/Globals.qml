pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Central UI state + IPC entry points, so niri keybinds can drive the shell:
//   qs ipc call launcher   toggle
//   qs ipc call wifi       toggle
//   qs ipc call bluetooth  toggle
//   qs ipc call power      toggle
//   qs ipc call brightness osd
Singleton {
    id: root

    property bool launcherOpen: false
    property bool wifiOpen: false
    property bool bluetoothOpen: false
    property bool nightlightOpen: false
    property bool powerOpen: false

    // On-screen display (shared by volume + brightness)
    property string osdKind: ""     // "volume" | "brightness"
    property int osdValue: 0
    property bool osdMuted: false
    property bool osdVisible: false

    // Only one popup panel at a time (launcher/wifi/bt/nightlight/power).
    function _closeAll() {
        launcherOpen = false;
        wifiOpen = false;
        bluetoothOpen = false;
        nightlightOpen = false;
        powerOpen = false;
    }

    function toggleLauncher() { const v = !launcherOpen; _closeAll(); launcherOpen = v; }
    function toggleWifi()     { const v = !wifiOpen;     _closeAll(); wifiOpen = v; }
    function toggleBluetooth(){ const v = !bluetoothOpen;_closeAll(); bluetoothOpen = v; }
    function toggleNightlight(){ const v = !nightlightOpen; _closeAll(); nightlightOpen = v; }
    function togglePower()    { const v = !powerOpen;    _closeAll(); powerOpen = v; }

    Timer {
        id: osdTimer
        interval: 1500
        onTriggered: root.osdVisible = false
    }
    function showOsd(kind, value, muted) {
        root.osdKind = kind;
        root.osdValue = value;
        root.osdMuted = muted === true;
        root.osdVisible = true;
        osdTimer.restart();
    }

    IpcHandler {
        target: "launcher"
        function toggle() { root.toggleLauncher(); }
        function open() { root._closeAll(); root.launcherOpen = true; }
        function close() { root.launcherOpen = false; }
    }
    IpcHandler {
        target: "wifi"
        function toggle() { root.toggleWifi(); }
    }
    IpcHandler {
        target: "bluetooth"
        function toggle() { root.toggleBluetooth(); }
    }
    IpcHandler {
        target: "nightlight"
        function toggle() { root.toggleNightlight(); }
    }
    IpcHandler {
        target: "power"
        function toggle() { root.togglePower(); }
    }
}
