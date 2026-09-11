# quickshellku

A [Quickshell](https://quickshell.outfoxxed.me/) desktop shell that mirrors my
Waybar setup on **niri**, plus native panels for launcher, Wi-Fi, Bluetooth,
brightness/nightlight and power.

It is a faithful port of the Waybar `config.jsonc` + `style.css` (Base16 via
Flavours), reusing the same tools I already run:

| Piece | Backend |
|-------|---------|
| Theme | reads `~/.config/waybar/colors.css` (live-reloads with Flavours) |
| Bar | niri IPC (workspaces, window title, taskbar) |
| Sound | Pipewire/WirePlumber (native Quickshell service) |
| Brightness | `light` (`-G/-S/-A/-U`) + nightlight menu (`nightlight-fuzzel`) |
| Wi-Fi | `iwctl` (iwd) — panel + fallback to **impala** |
| Bluetooth | `bluetoothctl` (bluez) — panel + fallback to **bluetui** |
| Launcher | native, reads `.desktop` files (like fuzzel) |
| Power | native grid → delegates to your `power-fuzzel` script |
| Notifications | native daemon + toast popups (org.freedesktop.Notifications) |
| OSD | unified volume + brightness on-screen display |
| Tray | StatusNotifierItem (native) |

## Dependencies

Required:

- `quickshell` (git build recommended)
- `niri` (uses `niri msg --json event-stream`)
- Fonts: **Jetsevka** + **JetBrainsMono Nerd Font Propo** (same as your Waybar)

Per feature (you already have most of these):

- Sound: `pipewire`, `wireplumber`, `pavucontrol` (optional, opened on click)
- Brightness: `light`
- Wi-Fi: `iwd` (`iwctl`), `impala`, `rfkill`
- Bluetooth: `bluez` (`bluetoothctl`), `bluetui`
- Your existing scripts on `PATH`: `nightlight-fuzzel`, `power-fuzzel`, `footx`
- Stats: reads `/proc` + `df` (temp from `/sys/class/thermal/thermal_zone0`)

## Install

```sh
# clone this repo, then point Quickshell's default config at it:
ln -s "$PWD" ~/.config/quickshell/quickshellku
# or symlink the whole thing as the default:
#   ln -s "$PWD" ~/.config/quickshell

# run a named config:
qs -c quickshellku
# or if you symlinked it as the default:
qs
```

Autostart from niri (`~/.config/niri/config.kdl`):

```kdl
spawn-at-startup "qs" "-c" "quickshellku"
```

**Turn off Waybar** so they don't overlap (remove/comment your
`spawn-at-startup "waybar"`).

## Keybinds (niri)

The shell exposes IPC targets so keybinds drive it. Add to `config.kdl`:

```kdl
binds {
    Mod+D       { spawn "qs" "ipc" "call" "launcher" "toggle"; }
    Mod+W       { spawn "qs" "ipc" "call" "wifi" "toggle"; }
    Mod+B       { spawn "qs" "ipc" "call" "bluetooth" "toggle"; }
    Mod+N       { spawn "qs" "ipc" "call" "nightlight" "toggle"; }
    Mod+S       { spawn "qs" "ipc" "call" "quicksettings" "toggle"; }
    Mod+Escape  { spawn "qs" "ipc" "call" "power" "toggle"; }

    // brightness via the shell (the OSD pops up automatically)
    XF86MonBrightnessUp   { spawn "qs" "ipc" "call" "brightness" "up"; }
    XF86MonBrightnessDown { spawn "qs" "ipc" "call" "brightness" "down"; }

    // volume keys (wpctl) — the OSD pops up automatically on the change
    XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "-l" "1" "@DEFAULT_AUDIO_SINK@" "5%+"; }
    XF86AudioLowerVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
    XF86AudioMute        { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
}
```

(If you symlinked as the default config, drop the `"-c" "quickshellku"` / `-c`
parts and just use `qs`.)

You can also click the bar:

- **Menu button** (left, orange) → launcher
- **Stats capsule** (cpu/mem/disk/temp) → opens `btop`
- **Control cluster** (volume/wifi/bt icons) → Quick Settings panel · scroll → volume
- **Quick Settings panel**: volume + brightness sliders, and WiFi / Bluetooth /
  Night light tiles — click a tile toggles it, right-click opens its detailed
  panel (network list / bluetooth devices / nightlight)
- **Power button** (right, red) → power menu
- **Clock** → toggle time / full date

## Theming

Colours come from `~/.config/waybar/colors.css` (the Flavours output your
Waybar already imports). When Flavours reskins, Quickshell picks it up live.
No colors file? Sensible Base16 defaults are used. You can also hardcode
colours or change fonts/sizes in `services/Theme.qml`.

## Layout of the config

```
shell.qml            entry point (bars + popups)
Bar.qml              the bottom bar (Waybar port)
services/            singletons (state + backends)
  Theme.qml          Base16 palette from colors.css
  Niri.qml           niri IPC (workspaces / windows / focus)
  SystemStats.qml    cpu / mem / disk / temp
  Brightness.qml     `light`
  Network.qml        iwd via iwctl
  Bluetooth.qml      bluez via bluetoothctl
  Globals.qml        UI state + IPC handlers
modules/             bar widgets (pills, workspaces, tray, clock, …)
popups/              launcher, wifi, bluetooth, power, brightness OSD
```

## Notes / troubleshooting

- **Nothing shows up:** run `qs -c quickshellku` in a terminal and read the
  logs — QML errors print there with file:line.
- **Icons are boxes:** install the Nerd Font (JetBrainsMono Nerd Font Propo)
  and confirm `Theme.fontFamilyFallback` matches its exact family name.
- **Wrong temp:** set `zonePath` in `services/SystemStats.qml` to your sensor
  (check `for f in /sys/class/thermal/thermal_zone*/type; do echo $f $(cat $f); done`).
- **Wi-Fi list empty / odd:** iwctl output is colourful and hard to parse;
  the panel does its best but the reliable path is the **impala** button
  (right-click the Wi-Fi pill).
- **Workspace click focuses the wrong one on multi-monitor:** niri references
  workspaces by index/name; tweak `focusWorkspace()` in `services/Niri.qml`
  if needed.
- **Tray context menus:** left-click activates, other clicks trigger the
  secondary action. Full nested SNI menus aren't rendered yet.
