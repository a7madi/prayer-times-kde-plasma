import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "translations/Translations.js" as T

KCM.SimpleKCM {
    id: page

    property string cfg_language
    readonly property string lang: T.resolve(cfg_language)
    LayoutMirroring.enabled: T.locale(lang).textDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true
    function tr(text, ...args) { return T.tr(lang, text, args); }

    property alias cfg_notifyEnabled: enabledBox.checked
    property alias cfg_notifyFajr: nFajr.checked
    property alias cfg_notifySunrise: nSunrise.checked
    property alias cfg_notifyDhuhr: nDhuhr.checked
    property alias cfg_notifyAsr: nAsr.checked
    property alias cfg_notifyMaghrib: nMaghrib.checked
    property alias cfg_notifyIsha: nIsha.checked
    property int cfg_soundMode
    property string cfg_adhanFile
    property string cfg_fajrAdhanFile
    property alias cfg_volume: volumeSlider.value
    property bool cfg_adhanFull
    property alias cfg_adhanSeconds: secondsSpin.value
    property alias cfg_reminderMinutes: reminderSpin.value
    property alias cfg_soundInDnd: dndBox.checked

    function displayPath(url) {
        return url ? decodeURIComponent(url.toString().replace(/^file:\/\//, "")) : "";
    }

    // Lets the user hear the file and set the volume before relying on it.
    AdhanPlayer { id: tester; volume: volumeSlider.value / 100 }

    FileDialog {
        id: fileDialog
        property bool forFajr: false
        title: page.tr("Choose adhan file")
        nameFilters: [page.tr("Audio files") + " (*.mp3 *.ogg *.oga *.opus *.wav *.flac *.m4a)"]
        onAccepted: {
            if (forFajr) page.cfg_fajrAdhanFile = selectedFile.toString();
            else page.cfg_adhanFile = selectedFile.toString();
        }
    }

    component FileRow: RowLayout {
        id: fileRow
        property string url
        property bool fajr: false
        property string placeholder
        QQC2.TextField {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 14
            readOnly: true
            text: page.displayPath(fileRow.url)
            placeholderText: fileRow.placeholder
            LayoutMirroring.enabled: false
            horizontalAlignment: Text.AlignLeft
        }
        QQC2.Button {
            icon.name: "document-open"
            QQC2.ToolTip.text: page.tr("Choose…")
            QQC2.ToolTip.visible: hovered
            onClicked: { fileDialog.forFajr = fileRow.fajr; fileDialog.open(); }
        }
        QQC2.Button {
            icon.name: tester.playing ? "media-playback-stop" : "media-playback-start"
            enabled: fileRow.url !== "" || tester.playing
            QQC2.ToolTip.text: page.tr("Test")
            QQC2.ToolTip.visible: hovered
            onClicked: tester.playing ? tester.stop()
                : tester.play([fileRow.url], page.cfg_adhanFull ? 0 : secondsSpin.value)
        }
        QQC2.Button {
            icon.name: "edit-clear"
            enabled: fileRow.url !== ""
            QQC2.ToolTip.text: page.tr("Clear")
            QQC2.ToolTip.visible: hovered
            onClicked: fileRow.fajr ? page.cfg_fajrAdhanFile = "" : page.cfg_adhanFile = ""
        }
    }

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: enabledBox
            Kirigami.FormData.label: page.tr("Alerts:")
            text: page.tr("Notify me when prayer time starts")
        }

        ColumnLayout {
            Kirigami.FormData.label: page.tr("Prayers:")
            enabled: enabledBox.checked
            spacing: 0
            QQC2.CheckBox { id: nFajr;    text: page.tr("Fajr") }
            QQC2.CheckBox { id: nSunrise; text: page.tr("Sunrise") }
            QQC2.CheckBox { id: nDhuhr;   text: page.tr("Dhuhr") }
            QQC2.CheckBox { id: nAsr;     text: page.tr("Asr") }
            QQC2.CheckBox { id: nMaghrib; text: page.tr("Maghrib") }
            QQC2.CheckBox { id: nIsha;    text: page.tr("Isha") }
        }

        QQC2.SpinBox {
            id: reminderSpin
            enabled: enabledBox.checked
            Kirigami.FormData.label: page.tr("Remind before (min):")
            from: 0; to: 60
            textFromValue: (v) => v === 0 ? page.tr("Off") : String(v)
            valueFromText: (t) => parseInt(t) || 0
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: page.tr("Sound") }

        ColumnLayout {
            Kirigami.FormData.label: page.tr("Sound:")
            enabled: enabledBox.checked
            spacing: 0
            QQC2.RadioButton {
                text: page.tr("Silent (notification only)")
                checked: page.cfg_soundMode === 0
                onToggled: if (checked) page.cfg_soundMode = 0
            }
            QQC2.RadioButton {
                text: page.tr("System notification sound")
                checked: page.cfg_soundMode === 1
                onToggled: if (checked) page.cfg_soundMode = 1
            }
            QQC2.RadioButton {
                text: page.tr("My own adhan file")
                checked: page.cfg_soundMode === 2
                onToggled: if (checked) page.cfg_soundMode = 2
            }
        }

        FileRow {
            Kirigami.FormData.label: page.tr("Adhan file:")
            visible: page.cfg_soundMode === 2
            enabled: enabledBox.checked
            url: page.cfg_adhanFile
            placeholder: page.tr("No file chosen")
        }
        FileRow {
            Kirigami.FormData.label: page.tr("Fajr adhan:")
            visible: page.cfg_soundMode === 2
            enabled: enabledBox.checked
            fajr: true
            url: page.cfg_fajrAdhanFile
            placeholder: page.tr("Optional — same as above")
        }

        ColumnLayout {
            Kirigami.FormData.label: page.tr("Adhan length:")
            visible: page.cfg_soundMode === 2
            enabled: enabledBox.checked
            spacing: 0
            QQC2.RadioButton {
                text: page.tr("Full")
                checked: page.cfg_adhanFull
                onToggled: if (checked) page.cfg_adhanFull = true
            }
            RowLayout {
                QQC2.RadioButton {
                    id: limitedRadio
                    text: page.tr("First")
                    checked: !page.cfg_adhanFull
                    onToggled: if (checked) page.cfg_adhanFull = false
                }
                QQC2.SpinBox { id: secondsSpin; from: 5; to: 300; enabled: limitedRadio.checked }
                QQC2.Label { text: page.tr("seconds (with fade-out)") }
            }
        }

        RowLayout {
            Kirigami.FormData.label: page.tr("Volume:")
            enabled: enabledBox.checked && page.cfg_soundMode !== 0
            QQC2.Slider {
                id: volumeSlider
                from: 0; to: 100; stepSize: 5
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            }
            QQC2.Label { text: volumeSlider.value + "%" }
        }

        QQC2.CheckBox {
            id: dndBox
            enabled: enabledBox.checked && page.cfg_soundMode !== 0
            text: page.tr("Play sound even in Do Not Disturb mode")
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: page.tr("To stop the adhan: use the Stop button in the notification, or click the widget.")
        }
    }
}
