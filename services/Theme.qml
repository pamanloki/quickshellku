pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Base16 theme, auto-synced from your Flavours-generated Waybar colors.
// It reads ~/.config/waybar/colors.css (the same file your Waybar imports)
// and live-reloads when Flavours rewrites it, so Quickshell always matches
// your current theme. If the file is missing, the defaults below are used.
Singleton {
    id: root

    // ---- Base16 palette (defaults = Base16 "Default Dark") ----
    property color base00: "#181818" // background
    property color base01: "#282828" // lighter background (pills)
    property color base02: "#383838" // selection / icon pills
    property color base03: "#585858" // comments / dim
    property color base04: "#b8b8b8"
    property color base05: "#d8d8d8" // default foreground
    property color base06: "#e8e8e8"
    property color base07: "#f8f8f8"
    property color base08: "#ab4642" // red
    property color base09: "#dc9656" // orange
    property color base0A: "#f7ca88" // yellow
    property color base0B: "#a1b56c" // green
    property color base0C: "#86c1b9" // cyan
    property color base0D: "#7cafc2" // blue
    property color base0E: "#ba8baf" // magenta
    property color base0F: "#a16946" // brown

    // ---- Fonts (from your Waybar style.css) ----
    property string fontFamily: "Jetsevka"
    property string fontFamilyFallback: "JetBrainsMono Nerd Font Propo"
    readonly property var fontList: [fontFamily, fontFamilyFallback]
    property int fontSize: 17
    property int fontWeight: Font.Bold

    // ---- Bar geometry (bump barHeight/fontSize if it looks tiny on HiDPI) ----
    property int barHeight: 40
    property int pillVMargin: 6        // vertical margin around pills
    property int pillHPad: 8           // horizontal padding inside pills
    property int pillGap: 5            // gap between module groups
    property int radius: 0             // Waybar uses square corners here

    // ---- Screen border (caelestia-style inset frame) ----
    // The desktop/wallpaper gets a coloured margin on every edge with rounded
    // inner corners, so it no longer bleeds to the screen edge. Set
    // borderThickness to 0 to disable the frame entirely.
    property int borderThickness: 10   // margin reserved on each edge
    property int borderRounding: 20    // inner corner radius of the frame

    // ---- Animation (Material 3 "expressive" motion, from caelestia) ----
    // Spatial = movement/scale/size; it overshoots slightly (y goes past 1) for
    // a lively spring feel. Effects = fades; no overshoot.
    readonly property var easeSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property var easeEffects: [0.34, 0.80, 0.34, 1, 1, 1]
    readonly property var easeEmphasized: [0.05, 0, 2.0/15.0, 0.06, 1.0/6.0, 0.4, 5.0/24.0, 0.82, 0.25, 1, 1, 1]
    property int durSpatial: 500        // popup open/scale
    property int durEffects: 200        // fades

    // Path to the Flavours colors file (same one Waybar imports).
    property string colorsPath: Quickshell.env("HOME") + "/.config/waybar/colors.css"

    function parseColors(txt) {
        if (!txt)
            return;
        // Matches lines like: @define-color base00 #1d1f21;
        const re = /@define-color\s+(base[0-9A-Fa-f]{2})\s+(#[0-9A-Fa-f]{3,8})/g;
        let m;
        while ((m = re.exec(txt)) !== null) {
            // Normalise key to the property name (base00..base09, base0A..base0F)
            const name = "base" + m[1].slice(4).toUpperCase();
            if (root.hasOwnProperty(name))
                root[name] = m[2];
        }
    }

    FileView {
        id: colorFile
        path: root.colorsPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parseColors(text())
    }
}
