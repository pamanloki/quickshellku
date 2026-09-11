pragma Singleton

import Quickshell
import Quickshell.Services.Mpris

// Active MPRIS player (music/media), for the Quick Settings mini player.
Singleton {
    id: root

    readonly property var player: {
        const ps = Mpris.players ? Mpris.players.values : [];
        if (!ps || ps.length === 0)
            return null;
        for (const p of ps)
            if (p.playbackState === MprisPlaybackState.Playing)
                return p;
        return ps[0];
    }

    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: player && player.playbackState === MprisPlaybackState.Playing
    readonly property string title: player && player.trackTitle ? player.trackTitle : ""
    readonly property string artist: player && player.trackArtist ? player.trackArtist : ""
    readonly property string artUrl: player && player.trackArtUrl ? player.trackArtUrl : ""

    function playPause() {
        if (player && player.canTogglePlaying)
            player.togglePlaying();
    }
    function next() {
        if (player && player.canGoNext)
            player.next();
    }
    function previous() {
        if (player && player.canGoPrevious)
            player.previous();
    }
}
