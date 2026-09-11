//@ pragma UseQApplication

import Quickshell
import "root:/services"
import "root:/popups"

ShellRoot {
    id: shell

    // Force-instantiate singletons that run background services / own the
    // IpcHandlers, so they're live from startup (not just on first reference).
    readonly property var _services: [
        Globals, Theme, Niri, SystemStats, Brightness, Network, Bluetooth, Nightlight,
        Notifications, Player, Flavours, Time, Wallpaper, Audio, Screenshot, Updates
    ]

    // One bar per monitor.
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // Popups / overlays (each handles its own per-screen instancing + visibility).
    Launcher {}
    WifiPanel {}
    BluetoothPanel {}
    NightlightPanel {}
    QuickSettingsPanel {}
    CalendarPanel {}
    ThemePanel {}
    WallpaperPanel {}
    PowerMenu {}
    Osd {}
    NotificationToasts {}
    NotificationCenter {}
    TrayMenu {}
    ScreenshotMenu {}
}
