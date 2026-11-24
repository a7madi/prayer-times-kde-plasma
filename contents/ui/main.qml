import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.notification
import "PrayTimes.js" as PT
import "translations/Translations.js" as T

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration
    readonly property string lang: T.resolve(cfg.language)
    readonly property var loc: T.locale(lang)
    readonly property bool rtl: loc.textDirection === Qt.RightToLeft
    function tr(text, ...args) { return T.tr(lang, text, args); }
    readonly property var names: ({
        fajr: tr("Fajr"), sunrise: tr("Sunrise"), dhuhr: tr("Dhuhr"),
        asr: tr("Asr"), maghrib: tr("Maghrib"), isha: tr("Isha")
    })

    property var today: []        // [{key, date}]
    property var tomorrow: []
    property var yesterday: []
    property var schedule: []     // what the popup lists: today, or tomorrow once Isha has passed
    readonly property bool showingTomorrow: schedule === tomorrow && tomorrow.length > 0
    property var nextPrayer: null // {key, date}
    property var lastPrayer: null // most recent prayer that already started
    property date now: new Date()
    property string computedFor: ""

    readonly property int msLeft: nextPrayer ? nextPrayer.date - now : 0
    readonly property bool isNow: lastPrayer !== null && cfg.highlightMinutes > 0
        && (now - lastPrayer.date) < cfg.highlightMinutes * 60000
    readonly property bool isSoon: msLeft > 0 && msLeft < cfg.soonMinutes * 60000

    // ---------- helpers ----------
    // Convert any digits (Latin, Arabic-Indic, Persian) to the chosen language's digits.
    function localDigits(s) {
        const zero = loc.zeroDigit.charCodeAt(0);
        return s.replace(/[0-9\u0660-\u0669\u06F0-\u06F9]/g, c => {
            const code = c.charCodeAt(0);
            const v = code <= 57 ? code - 48 : code >= 0x06F0 ? code - 0x06F0 : code - 0x0660;
            return String.fromCharCode(zero + v);
        });
    }
    function fmtTime(d) {
        return d ? localDigits(loc.toString(d, cfg.use24h ? "HH:mm" : "h:mm AP")) : "--:--";
    }
    function fmtCountdown(ms) {
        const total = Math.max(0, Math.ceil(ms / 1000));
        const h = Math.floor(total / 3600), m = Math.floor((total % 3600) / 60), s = total % 60;
        let txt;
        if (total < 60)      txt = tr("%1s", s);
        else if (h === 0)    txt = tr("%1m", Math.ceil(total / 60));
        else                 txt = tr("%1h %2m", h, m);
        return localDigits(txt);
    }
    function offsets() {
        return { fajr: cfg.offsetFajr, sunrise: cfg.offsetSunrise, dhuhr: cfg.offsetDhuhr,
                 asr: cfg.offsetAsr, maghrib: cfg.offsetMaghrib, isha: cfg.offsetIsha };
    }
    function calc(day) {
        return PT.computeDay(day, cfg.latitude, cfg.longitude, cfg.method, cfg.asrMethod + 1, offsets());
    }

    function recalc() {
        const d = new Date();
        computedFor = d.toDateString();
        today = calc(d);
        const t = new Date(d); t.setDate(t.getDate() + 1);
        tomorrow = calc(t);
        const y = new Date(d); y.setDate(y.getDate() - 1);
        yesterday = calc(y);
        update();
    }

    function update() {
        now = new Date();
        if (now.toDateString() !== computedFor) { recalc(); return; }

        const prayers = today.filter(p => p.date && (cfg.countSunrise || p.key !== "sunrise"));
        let next = null, last = null;
        for (const p of prayers) {
            if (p.date > now) { next = p; break; }
            last = p;
        }
        const afterIsha = !next;
        if (afterIsha) next = tomorrow.find(p => p.date);
        if (!last) last = yesterday.filter(p => p.date && p.key !== "sunrise").pop() || null;
        const target = afterIsha ? tomorrow : today;
        if (schedule !== target) schedule = target;   // only reassign on change, avoids rebuilding the list every second
        nextPrayer = next;
        lastPrayer = last;
        checkAlerts();
    }

    // ---------- alerts ----------
    function alertEnabledFor(key) {
        return cfg["notify" + key.charAt(0).toUpperCase() + key.slice(1)];
    }

    function checkAlerts() {
        if (!cfg.notifyEnabled) return;
        const rem = cfg.reminderMinutes * 60000;
        for (const p of today) {
            if (!p.date || !alertEnabledFor(p.key)) continue;
            const id = p.key + "@" + p.date.getTime();
            const since = now - p.date;
            // Only fire within 2 minutes of the time, so waking from sleep doesn't play a late adhan.
            // The id is stored in the config so restarting plasmashell doesn't repeat it.
            if (since >= 0 && since < 120000 && cfg.lastNotified !== id) {
                cfg.lastNotified = id;
                fireAdhan(p);
            }
            const until = p.date - now;
            if (rem > 0 && until > 0 && until <= rem && until > rem - 120000 && cfg.lastReminded !== id) {
                cfg.lastReminded = id;
                fireReminder(p, until);
            }
        }
    }

    function fireAdhan(p) {
        const sunrise = p.key === "sunrise";
        const dnd = !cfg.soundInDnd && dndLoader.item ? dndLoader.item.isActive() : false;
        const withSound = cfg.soundMode !== 0 && !dnd;
        const title = sunrise ? tr("Sunrise time") : tr("It's time for %1 prayer", names[p.key]);
        (withSound ? adhanNotification : plainNotification)
            .createObject(root, { title: title, text: fmtTime(p.date) }).sendEvent();
        if (withSound) playFor(p.key);
    }

    function fireReminder(p, until) {
        plainNotification.createObject(root, {
            title: tr("%1 in %2", names[p.key], fmtCountdown(until)),
            text: fmtTime(p.date)
        }).sendEvent();
    }

    function playFor(key) {
        // Sunrise isn't an adhan: always the short system sound.
        const custom = cfg.soundMode === 2 && key !== "sunrise";
        let sources = [];
        if (custom) sources.push(key === "fajr" && cfg.fajrAdhanFile ? cfg.fajrAdhanFile : cfg.adhanFile);
        sources = sources.concat(adhan.systemSounds);  // fallback if the file is missing
        adhan.play(sources, custom && !cfg.adhanFull ? cfg.adhanSeconds : 0);
    }

    function stopAdhan() { adhan.stop(); }

    AdhanPlayer { id: adhan; volume: root.cfg.volume / 100 }
    Loader { id: dndLoader; source: "DndWatcher.qml" }

    Component {
        id: adhanNotification
        Notification {
            componentName: "plasma_workspace"
            eventId: "notification"
            iconName: "chronometer"
            actions: [
                NotificationAction {
                    label: root.tr("Stop adhan")
                    onActivated: root.stopAdhan()
                }
            ]
        }
    }
    Component {
        id: plainNotification
        Notification {
            componentName: "plasma_workspace"
            eventId: "notification"
            iconName: "chronometer"
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.update()
    }
    Connections {
        target: Plasmoid.configuration
        function onValueChanged(key) {
            if (key !== "lastNotified" && key !== "lastReminded") root.recalc();
        }
    }
    Component.onCompleted: recalc()

    function inText(ms) { return tr("in %1", fmtCountdown(ms)); }

    toolTipMainText: nextPrayer ? `${tr("Next prayer")}: ${names[nextPrayer.key]} ${fmtTime(nextPrayer.date)}` : ""
    toolTipSubText: nextPrayer ? inText(msLeft) : ""

    // ---------- panel ----------
    compactRepresentation: MouseArea {
        id: compact
        readonly property bool twoLines: height >= Kirigami.Units.gridUnit * 2
            && Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        readonly property color accent: root.isNow ? Kirigami.Theme.positiveTextColor
                                      : root.isSoon ? Kirigami.Theme.neutralTextColor
                                      : Kirigami.Theme.textColor

        Layout.minimumWidth: grid.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        hoverEnabled: true
        onClicked: {
            if (adhan.playing) adhan.stop();   // click while adhan plays = stop it
            else root.expanded = !root.expanded;
        }

        RowLayout {
            id: grid
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                visible: adhan.playing
                source: "media-playback-stop"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                color: compact.accent
            }

        GridLayout {
            flow: compact.twoLines ? GridLayout.TopToBottom : GridLayout.LeftToRight
            rows: compact.twoLines ? 2 : 1
            rowSpacing: 0
            columnSpacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignHCenter
                text: root.isNow ? root.names[root.lastPrayer.key]
                    : root.nextPrayer ? root.names[root.nextPrayer.key] + "  " + root.fmtTime(root.nextPrayer.date) : "—"
                color: compact.accent
                font.bold: true
            }
            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignHCenter
                text: root.isNow ? root.tr("now")
                    : root.nextPrayer ? (compact.twoLines ? "" : "· ") + root.inText(root.msLeft) : ""
                color: compact.accent
                opacity: root.isNow ? 1 : 0.8
                font.pointSize: compact.twoLines ? Kirigami.Theme.smallFont.pointSize : Kirigami.Theme.defaultFont.pointSize
            }
        }
        }
    }

    // ---------- popup ----------
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 15
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        spacing: Kirigami.Units.smallSpacing
        LayoutMirroring.enabled: root.rtl
        LayoutMirroring.childrenInherit: true

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            horizontalAlignment: Text.AlignHCenter
            text: root.tr("Next prayer")
            font: Kirigami.Theme.smallFont
            opacity: 0.6
        }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 2
            horizontalAlignment: Text.AlignHCenter
            text: root.nextPrayer ? root.names[root.nextPrayer.key] : ""
        }
        PlasmaComponents3.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.nextPrayer ? root.inText(root.msLeft) : ""
            opacity: 0.8
        }

        PlasmaComponents3.Button {
            Layout.alignment: Qt.AlignHCenter
            visible: adhan.playing
            icon.name: "media-playback-stop"
            text: root.tr("Stop adhan")
            onClicked: adhan.stop()
        }

        Kirigami.Separator { Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.smallSpacing }

        PlasmaComponents3.Label {
            visible: root.showingTomorrow
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.tr("Tomorrow")
            font: Kirigami.Theme.smallFont
            opacity: 0.6
        }

        Repeater {
            model: root.schedule
            delegate: Rectangle {
                required property var modelData
                readonly property bool isNext: root.nextPrayer && root.nextPrayer.date
                    && modelData.date && root.nextPrayer.date.getTime() === modelData.date.getTime()
                readonly property bool passed: modelData.date && modelData.date < root.now

                Layout.fillWidth: true
                implicitHeight: row.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.cornerRadius
                color: isNext ? Qt.alpha(Kirigami.Theme.highlightColor, 0.25) : "transparent"

                RowLayout {
                    id: row
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.largeSpacing
                    anchors.rightMargin: Kirigami.Units.largeSpacing
                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: root.names[modelData.key]
                        font.bold: isNext
                        opacity: passed && !isNext ? 0.55 : 1
                    }
                    PlasmaComponents3.Label {
                        text: root.fmtTime(modelData.date)
                        font.bold: isNext
                        opacity: passed && !isNext ? 0.55 : 1
                    }
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            font: Kirigami.Theme.smallFont
            opacity: 0.6
            text: root.localDigits(Number(root.cfg.latitude).toFixed(4) + ", " + Number(root.cfg.longitude).toFixed(4))
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: root.tr("Refresh")
            icon.name: "view-refresh"
            onTriggered: root.recalc()
        }
    ]
}
