# labwc config for quickshellku

A labwc setup wired to this shell, for people who want macOS-like **floating
windows** instead of niri's tiling. Copy these into `~/.config/labwc/`:

```sh
cp contrib/labwc/{rc.xml,menu.xml,autostart,environment} ~/.config/labwc/
chmod +x ~/.config/labwc/autostart
```

## What's wired

- **Autostart** launches `quickshell` (the bar/dock/panels) and `swww-daemon`
  (the wallpaper daemon `awww` drives). Night Light is left to the shell.
- **Mod = Super (`W`)**, same as niri's default.
- App launcher, screenshots, power menu and notifications go through the
  shell's IPC (`qs ipc call ...`) — no rofi/waybar needed.
- Volume uses **wpctl** (PipeWire); brightness **brightnessctl**; media keys
  **playerctl**. The shell's OSD pops up on change automatically.

## Key binds

| Keys | Action |
|------|--------|
| `Super`+`Return` | Terminal (foot) |
| `Super`+`D` / `Super`+`Shift`+`Return` | Launcher (`;` = clipboard, `>` = run) |
| `Super`+`E` | Files (pcmanfm) |
| `Super`+`B` | Browser (brave) |
| `Super`+`Q` / `Alt`+`F4` | Close window |
| `Super`+`Space` / `Super`+`Up` | Maximize |
| `Super`+`F` | Fullscreen |
| `Super`+`Left`/`Right`/`Down` | Snap to edge |
| `Super`+`C` | Centre window |
| `Alt`+`Tab` | Window switcher |
| `Super`+`1..5` | Workspace; `+Shift` moves window |
| `Super`+`Ctrl`+`Left`/`Right` | Prev/next workspace |
| `Print` | Screenshot region→clipboard (full) |
| `Super`+`Print` | Screenshot region |
| `Super`+`Shift`+`S` | Screenshot menu |
| `Super`+`Escape` | Power menu |
| `Super`+`N` | Notification centre |
| `Super`+`Ctrl`+`Backspace` | Quit labwc |

Adjust the terminal/browser/file-manager commands and any key you want — this
matches quickshellku's commands, not a 1:1 copy of a specific niri config, so
tweak the keys to your taste.

## Notes

- If your quickshell config lives at `~/.config/quickshell/quickshellku`
  rather than the default dir, start it with `quickshell -c quickshellku` in
  `autostart`.
- `environment` sets `us,fr` layouts (toggle RCtrl+RShift) — edit to your own.

## ⚠️ Known limitation on labwc

The dock's **running-app tracking, focus and close** (and the app-name in the
menu bar, the dock window menu) currently talk to **niri** via `niri msg`
(`services/Niri.qml`). Under labwc there is no niri IPC, so on labwc the dock
will show only pinned apps, and clicking/closing running windows won't work
until that service is ported to the **wlr-foreign-toplevel** protocol
(Quickshell's `ToplevelManager`). Everything else (menu bar, Control Centre,
Wi-Fi/BT/Audio/Battery/System panels, notifications, OSD, screenshots,
wallpaper, theme) is compositor-agnostic and works as-is.

If you switch to labwc, say the word and I'll add a wlroots window backend so
the dock keeps full functionality.
