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
    property bool quickSettingsOpen: false
    property bool calendarOpen: false
    property bool themeOpen: false
    property bool wallpaperOpen: false
    property bool powerOpen: false
    property bool notifsOpen: false
    property bool screenshotOpen: false
    property bool appleMenuOpen: false
    property bool aboutOpen: false
    property bool audioOpen: false
    property bool batteryOpen: false
    property bool systemOpen: false

    // macOS-style app switcher (⌘-Tab): a row of app icons; cycle with Tab,
    // confirm on release. Driven by:  qs ipc call switcher next | prev
    property bool switcherOpen: false
    property var switcherList: []      // [{norm, app_id, id}]
    property int switcherIndex: 0
    function _switcherNorm(s) { return (s || "").toLowerCase().replace(/[^a-z0-9]/g, ""); }

    // most-recently-used app order (norms, most recent first)
    property var _appMru: []
    Connections {
        target: Niri
        function onFocusedAppIdChanged() {
            const n = root._switcherNorm(Niri.focusedAppId || "");
            if (!n) return;
            const a = root._appMru.filter(x => x !== n);
            a.unshift(n);
            root._appMru = a;
        }
    }

    function _buildSwitcher() {
        const list = Niri.windowList || [];
        const byNorm = ({});
        for (let i = 0; i < list.length; i++) {
            const n = _switcherNorm(list[i].app_id || "?");
            if (!byNorm[n]) byNorm[n] = { norm: n, app_id: list[i].app_id || "?", id: list[i].id };
        }
        const out = [];
        const used = ({});
        // MRU first (running apps only), then any remaining running apps
        for (const n of root._appMru)
            if (byNorm[n] && !used[n]) { out.push(byNorm[n]); used[n] = true; }
        for (const n in byNorm)
            if (!used[n]) out.push(byNorm[n]);
        return out;
    }
    function switcherStep(dir) {
        if (!switcherOpen) {
            const l = _buildSwitcher();
            if (l.length === 0) return;
            switcherList = l;
            // start on the currently-focused app
            const f = _switcherNorm(Niri.focusedAppId || "");
            let idx = 0;
            for (let i = 0; i < l.length; i++) if (l[i].norm === f) { idx = i; break; }
            switcherIndex = idx;
            switcherOpen = true;
        } else {
            const n = switcherList.length;
            if (n === 0) return;
            switcherIndex = ((switcherIndex + dir) % n + n) % n;
        }
    }
    function switcherConfirm() {
        if (!switcherOpen) return;
        const e = switcherList[switcherIndex];
        switcherOpen = false;
        if (e) Niri.focusWindow(e.id);
    }
    function switcherCancel() { switcherOpen = false; }

    // Dock auto-hide (macOS "Turn Hiding On"): dock slides off-screen and
    // reveals when the cursor reaches the bottom edge — keeps the dock out of
    // the way of fullscreen apps / games.
    property bool dockAutoHide: false
    function toggleDockAutoHide() { dockAutoHide = !dockAutoHide; }

    // Tray context menu (right-click a tray icon).
    property bool trayMenuOpen: false
    property var trayMenuHandle: null
    property real trayMenuX: 0
    function openTrayMenu(handle, x) {
        _closeAll();
        trayMenuHandle = handle;
        trayMenuX = x;
        trayMenuOpen = true;
    }

    // Dock window menu (right-click a dock icon → pick a window / pin toggle).
    property bool dockMenuOpen: false
    property var dockMenuWindows: []
    property real dockMenuX: 0
    property string dockMenuAppId: ""    // app whose menu is open (for pin/unpin)
    function openDockMenu(wins, x, appId) {
        _closeAll();
        dockMenuWindows = wins;
        dockMenuX = x;
        dockMenuAppId = appId || "";
        dockMenuOpen = true;
    }

    // Screen-x (centre) of the menu-bar item that opened the current panel, so
    // right-cluster dropdowns can appear under their icon instead of the corner.
    // -1 = no anchor (hug the right edge).
    property real panelX: -1

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
        quickSettingsOpen = false;
        calendarOpen = false;
        themeOpen = false;
        wallpaperOpen = false;
        powerOpen = false;
        notifsOpen = false;
        trayMenuOpen = false;
        dockMenuOpen = false;
        screenshotOpen = false;
        appleMenuOpen = false;
        aboutOpen = false;
        audioOpen = false;
        batteryOpen = false;
        systemOpen = false;
        panelX = -1;
    }

    function toggleLauncher() { const v = !launcherOpen; _closeAll(); launcherOpen = v; }
    function toggleWifi()     { const v = !wifiOpen;     _closeAll(); wifiOpen = v; }
    function toggleBluetooth(){ const v = !bluetoothOpen;_closeAll(); bluetoothOpen = v; }
    function toggleNightlight(){ const v = !nightlightOpen; _closeAll(); nightlightOpen = v; }
    function toggleQuickSettings(){ const v = !quickSettingsOpen; _closeAll(); quickSettingsOpen = v; }
    function toggleCalendar(){ const v = !calendarOpen; _closeAll(); calendarOpen = v; }
    function toggleTheme()   { const v = !themeOpen;    _closeAll(); themeOpen = v; }
    function toggleWallpaper(){ const v = !wallpaperOpen; _closeAll(); wallpaperOpen = v; }
    function togglePower()    { const v = !powerOpen;    _closeAll(); powerOpen = v; }
    function toggleNotifs()   { const v = !notifsOpen;   _closeAll(); notifsOpen = v; }
    function toggleScreenshot(){ const v = !screenshotOpen; _closeAll(); screenshotOpen = v; }
    function toggleAppleMenu() { const v = !appleMenuOpen; _closeAll(); appleMenuOpen = v; }
    function showAbout()       { _closeAll(); aboutOpen = true; }
    function toggleAudio()     { const v = !audioOpen;     _closeAll(); audioOpen = v; }
    function toggleBattery()   { const v = !batteryOpen;   _closeAll(); batteryOpen = v; }
    function toggleSystem()    { const v = !systemOpen;    _closeAll(); systemOpen = v; }

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
        target: "quicksettings"
        function toggle() { root.toggleQuickSettings(); }
    }
    IpcHandler {
        target: "calendar"
        function toggle() { root.toggleCalendar(); }
    }
    IpcHandler {
        target: "theme"
        function toggle() { root.toggleTheme(); }
    }
    IpcHandler {
        target: "wallpaper"
        function toggle() { root.toggleWallpaper(); }
    }
    IpcHandler {
        target: "power"
        function toggle() { root.togglePower(); }
    }
    IpcHandler {
        target: "notifications"
        function toggle() { root.toggleNotifs(); }
    }
    IpcHandler {
        target: "screenshot"
        function toggle() { root.toggleScreenshot(); }
    }
    IpcHandler {
        target: "battery"
        function toggle() { root.toggleBattery(); }
    }
    IpcHandler {
        target: "dock"
        function autohide() { root.toggleDockAutoHide(); }
    }
    IpcHandler {
        target: "system"
        function toggle() { root.toggleSystem(); }
    }
    IpcHandler {
        target: "switcher"
        function next() { root.switcherStep(1); }
        function prev() { root.switcherStep(-1); }
        function confirm() { root.switcherConfirm(); }
        function cancel() { root.switcherCancel(); }
    }
}
