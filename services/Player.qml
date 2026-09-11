pragma Singleton

import Quickshell
import Quickshell.Services.Mpris

// Active MPRIS player for the Quick Settings mini player.
//
// Browsers (Brave/Chromium/Firefox) often register several MPRIS instances,
// some without metadata, so we pick the one that actually has a track title,
// preferring whichever is playing. Reading each player's trackTitle/state
// inside the binding keeps the selection reactive as metadata arrives.
Singleton {
    id: root

    readonly property var currentPlayer: {
        const ps = (Mpris.players && Mpris.players.values) ? Mpris.players.values : [];
        let titledPlaying = null, titled = null, playing = null;
        for (let i = 0; i < ps.length; i++) {
            const p = ps[i];
            if (!p)
                continue;
            const t = p.trackTitle;                                   // reactive read
            const isP = p.playbackState === MprisPlaybackState.Playing; // reactive read
            if (t && isP && !titledPlaying) titledPlaying = p;
            if (t && !titled) titled = p;
            if (isP && !playing) playing = p;
        }
        return titledPlaying || titled || playing || (ps.length > 0 ? ps[0] : null);
    }

    readonly property bool hasPlayer: currentPlayer !== null
    readonly property bool isPlaying: currentPlayer && currentPlayer.playbackState === MprisPlaybackState.Playing
    readonly property string title: currentPlayer && currentPlayer.trackTitle ? currentPlayer.trackTitle : ""
    readonly property string artist: currentPlayer && currentPlayer.trackArtist ? currentPlayer.trackArtist : ""
    readonly property string artUrl: currentPlayer && currentPlayer.trackArtUrl ? currentPlayer.trackArtUrl : ""

    // Position / length in seconds. MPRIS position isn't pushed automatically —
    // a consumer (e.g. the Quick Settings panel while open) pokes refreshPosition
    // on a timer so `position` re-reads without us polling all the time.
    readonly property real length: currentPlayer && currentPlayer.length ? currentPlayer.length : 0
    readonly property real position: currentPlayer && currentPlayer.position ? currentPlayer.position : 0
    readonly property bool canSeek: currentPlayer ? currentPlayer.canSeek : false
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    function refreshPosition() {
        if (currentPlayer)
            currentPlayer.positionChanged();
    }
    function seek(frac) {
        if (currentPlayer && currentPlayer.canSeek && currentPlayer.positionSupported)
            currentPlayer.position = Math.max(0, Math.min(1, frac)) * currentPlayer.length;
    }
    function fmtTime(sec) {
        if (!sec || sec < 0 || !isFinite(sec))
            return "0:00";
        sec = Math.floor(sec);
        const m = Math.floor(sec / 60);
        const s = sec % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function playPause() {
        if (currentPlayer && currentPlayer.canTogglePlaying)
            currentPlayer.togglePlaying();
    }
    function next() {
        if (currentPlayer && currentPlayer.canGoNext)
            currentPlayer.next();
    }
    function previous() {
        if (currentPlayer && currentPlayer.canGoPrevious)
            currentPlayer.previous();
    }
}
