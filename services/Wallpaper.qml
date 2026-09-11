pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper selector matching your wallpaper-selector.sh logic: find the
// current flavours theme, resolve its folder from ~/.config/flavours/walls.map,
// list images there, and apply with awww (full transition -> minimal -> plain).
Singleton {
    id: root

    property var walls: []   // absolute image paths for the current theme

    function refresh() { listProc.running = true; }

    function apply(path) {
        applyProc.command = ["sh", "-c",
            'awww img "$1" --resize crop --transition-type wipe --transition-duration 2 --transition-angle 30 --transition-fps 60 2>/dev/null || awww img "$1" --resize crop 2>/dev/null || awww img "$1" 2>/dev/null',
            "sh", path];
        applyProc.running = true;
    }

    Process {
        id: listProc
        command: ["sh", "-c",
            'theme=$(flavours current 2>/dev/null | head -1); ' +
            'map="${XDG_CONFIG_HOME:-$HOME/.config}/flavours/walls.map"; ' +
            'folder=""; ' +
            '[ -f "$map" ] && while read -r k v; do [ "$k" = "$theme" ] && { folder="$v"; break; }; done < "$map"; ' +
            'case "$folder" in "~"*) folder="$HOME${folder#\\~}";; esac; ' +
            '[ -d "$folder" ] && find "$folder" -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) | sort'
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.walls = text.trim().split("\n").filter(x => x.length > 0);
            }
        }
    }

    Process { id: applyProc }
}
