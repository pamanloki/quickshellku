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
