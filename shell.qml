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
        Notifications, Player, Flavours, Time, Wallpaper, Audio, Screenshot, Updates, SysInfo,
        Battery, DockConfig
    ]

    // macOS-style top menu bar + bottom dock, per monitor.
    Variants {
        model: Quickshell.screens
        MenuBar {}
    }
    Variants {
        model: Quickshell.screens
        Dock {}
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
    DockMenu {}
    AppleMenu {}
    AboutPanel {}
    SystemPanel {}
    AudioPanel {}
    BatteryPanel {}
    BatteryAlert {}
    ScreenshotMenu {}
    ScreenCorners {}
}
