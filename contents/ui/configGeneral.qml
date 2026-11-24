import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "translations/Translations.js" as T

KCM.SimpleKCM {
    id: page
    readonly property string lang: T.resolve(cfg_language)
    LayoutMirroring.enabled: T.locale(lang).textDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true
    function tr(text, ...args) { return T.tr(lang, text, args); }

    property double cfg_latitude
    property double cfg_longitude
    property string cfg_method
    property int cfg_asrMethod
    property string cfg_language
    property alias cfg_use24h: use24.checked
    property alias cfg_countSunrise: sunriseBox.checked
    property alias cfg_highlightMinutes: highlightSpin.value
    property alias cfg_soonMinutes: soonSpin.value
    property alias cfg_offsetFajr: offFajr.value
    property alias cfg_offsetSunrise: offSunrise.value
    property alias cfg_offsetDhuhr: offDhuhr.value
    property alias cfg_offsetAsr: offAsr.value
    property alias cfg_offsetMaghrib: offMaghrib.value
    property alias cfg_offsetIsha: offIsha.value

    component CoordField: QQC2.TextField {
        property real minV
        property real maxV
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        validator: DoubleValidator { bottom: minV; top: maxV; decimals: 6; locale: "C"; notation: DoubleValidator.StandardNotation }
        horizontalAlignment: Text.AlignLeft
        LayoutMirroring.enabled: false
    }
    component OffsetSpin: QQC2.SpinBox { from: -60; to: 60 }

    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: page.tr("Location") }

        CoordField {
            Kirigami.FormData.label: page.tr("Latitude:")
            minV: -90; maxV: 90
            text: String(page.cfg_latitude)
            onTextEdited: if (acceptableInput) page.cfg_latitude = parseFloat(text)
        }
        CoordField {
            Kirigami.FormData.label: page.tr("Longitude:")
            minV: -180; maxV: 180
            text: String(page.cfg_longitude)
            onTextEdited: if (acceptableInput) page.cfg_longitude = parseFloat(text)
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: page.tr("Example: Riyadh 24.7136, 46.6753 — long-press your location in Google Maps to copy coordinates.")
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: page.tr("Calculation") }

        QQC2.ComboBox {
            id: methodBox
            Kirigami.FormData.label: page.tr("Method:")
            textRole: "text"
            valueRole: "value"
            model: [
                { value: "makkah",  text: page.tr("Umm al-Qura, Makkah") },
                { value: "mwl",     text: page.tr("Muslim World League") },
                { value: "egypt",   text: page.tr("Egyptian General Authority") },
                { value: "karachi", text: page.tr("Univ. of Islamic Sciences, Karachi") },
                { value: "isna",    text: page.tr("ISNA (North America)") },
                { value: "gulf",    text: page.tr("Gulf region") },
                { value: "kuwait",  text: page.tr("Kuwait") },
                { value: "qatar",   text: page.tr("Qatar") },
                { value: "turkey",  text: page.tr("Turkey (approx.)") }
            ]
            // model is rebuilt when the language changes, so restore the selection
            onModelChanged: currentIndex = Math.max(0, indexOfValue(page.cfg_method))
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_method))
            onActivated: page.cfg_method = currentValue
        }
        QQC2.ComboBox {
            id: asrBox
            Kirigami.FormData.label: page.tr("Asr:")
            model: [page.tr("Standard (Shafi, Maliki, Hanbali)"),
                    page.tr("Hanafi")]
            onModelChanged: currentIndex = page.cfg_asrMethod
            Component.onCompleted: currentIndex = page.cfg_asrMethod
            onActivated: page.cfg_asrMethod = currentIndex
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: page.tr("Display") }

        QQC2.ComboBox {
            id: langBox
            Kirigami.FormData.label: page.tr("Language:")
            textRole: "name"
            valueRole: "code"
            model: T.languageList(page.tr("Automatic (system language)"))
            onModelChanged: currentIndex = Math.max(0, indexOfValue(page.cfg_language))
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_language))
            onActivated: page.cfg_language = currentValue
        }
        QQC2.CheckBox { id: use24; Kirigami.FormData.label: page.tr("Clock:"); text: page.tr("24-hour format") }
        QQC2.CheckBox { id: sunriseBox; text: page.tr("Count down to sunrise too") }
        QQC2.SpinBox {
            id: soonSpin
            Kirigami.FormData.label: page.tr("Warning color before prayer (min):")
            from: 0; to: 60
        }
        QQC2.SpinBox {
            id: highlightSpin
            Kirigami.FormData.label: page.tr("Show \"now\" for (min):")
            from: 0; to: 60
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: page.tr("Manual adjustments (min)") }

        OffsetSpin { id: offFajr;    Kirigami.FormData.label: page.tr("%1:", page.tr("Fajr")) }
        OffsetSpin { id: offSunrise; Kirigami.FormData.label: page.tr("%1:", page.tr("Sunrise")) }
        OffsetSpin { id: offDhuhr;   Kirigami.FormData.label: page.tr("%1:", page.tr("Dhuhr")) }
        OffsetSpin { id: offAsr;     Kirigami.FormData.label: page.tr("Asr:") }
        OffsetSpin { id: offMaghrib; Kirigami.FormData.label: page.tr("%1:", page.tr("Maghrib")) }
        OffsetSpin { id: offIsha;    Kirigami.FormData.label: page.tr("%1:", page.tr("Isha")) }
    }
}
