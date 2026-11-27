import QtQuick
import org.kde.plasma.plasma5support as P5Support

// Pauses every MPRIS media player that is currently playing (browsers, Spotify,
// VLC, KDE Connect…) and resumes exactly those players after a delay.
// Uses dbus-send, so no extra dependency is needed.
Item {
    id: pauser

    property var paused: []   // bus names we paused and should resume

    readonly property string pauseScript:
        "for s in $(dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus "
        + "org.freedesktop.DBus.ListNames | grep -o 'org\\.mpris\\.MediaPlayer2\\.[^\"]*'); do "
        + "dbus-send --session --print-reply --dest=$s /org/mpris/MediaPlayer2 "
        + "org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:PlaybackStatus "
        + "2>/dev/null | grep -q Playing && "
        + "dbus-send --session --dest=$s /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause && echo $s; "
        + "done"

    // Pause what's playing; resume it after `minutes`.
    function pauseFor(minutes) {
        resumeTimer.interval = Math.max(1, minutes) * 60000;
        resumeTimer.restart();
        exec.run("pause", pauseScript);
    }

    function resume() {
        resumeTimer.stop();
        const names = paused.filter(n => /^org\.mpris\.MediaPlayer2\.[\w.-]+$/.test(n));
        paused = [];
        if (!names.length) return;
        exec.run("resume", names.map(n =>
            "dbus-send --session --dest=" + n + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play"
        ).join("; "));
    }

    Timer { id: resumeTimer; onTriggered: pauser.resume() }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        property var kinds: ({})

        function run(kind, cmd) {
            // A unique suffix so the same command can run again while a previous one is cached.
            const src = cmd + " #" + Date.now();
            kinds[src] = kind;
            connectSource(src);
        }

        onNewData: (source, data) => {
            const kind = kinds[source];
            delete kinds[source];
            disconnectSource(source);
            if (kind === "pause") {
                const found = (data.stdout || "").split("\n").map(s => s.trim()).filter(s => s);
                // Merge, in case a second adhan fires while players are still paused.
                pauser.paused = pauser.paused.concat(found.filter(s => !pauser.paused.includes(s)));
            }
        }
    }
}
