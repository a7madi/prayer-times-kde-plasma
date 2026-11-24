import QtQuick
import QtMultimedia

// Plays a sound with optional time limit + fade-out, falling back to the
// next source in the list if a file can't be played.
Item {
    id: adhan

    property real volume: 0.8
    readonly property bool playing: player.playbackState === MediaPlayer.PlayingState

    property var queue: []
    property int limitSeconds: 0

    readonly property var systemSounds: [
        "file:///usr/share/sounds/ocean/stereo/message-new-instant.oga",
        "file:///usr/share/sounds/freedesktop/stereo/message-new-instant.oga",
        "file:///usr/share/sounds/freedesktop/stereo/complete.oga"
    ]

    // sources: list of URL strings, tried in order. limit: seconds, 0 = full length.
    function play(sources, limit) {
        stop();
        queue = sources.filter(s => !!s);
        limitSeconds = limit;
        playNext();
    }

    function playNext() {
        if (!queue.length) return;
        out.volume = volume;
        player.source = queue.shift();
        player.play();
        if (limitSeconds > 0) {
            cutTimer.interval = limitSeconds * 1000;
            cutTimer.restart();
        }
    }

    function stop() {
        cutTimer.stop();
        fadeTimer.stop();
        queue = [];
        player.stop();
    }

    MediaPlayer {
        id: player
        audioOutput: AudioOutput { id: out }
        onErrorOccurred: (error, errorString) => {
            console.warn("prayertimes: can't play", source, errorString);
            adhan.playNext();
        }
    }

    // Reached the time limit -> fade out over ~2.5 seconds instead of cutting abruptly.
    Timer { id: cutTimer; onTriggered: fadeTimer.start() }
    Timer {
        id: fadeTimer
        interval: 100
        repeat: true
        onTriggered: {
            out.volume = Math.max(0, out.volume - adhan.volume / 25);
            if (out.volume <= 0) adhan.stop();
        }
    }
}
