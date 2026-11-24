.pragma library

// Lightweight translation layer.
// KDE's gettext i18n always follows the system language, but this widget lets
// the user pick its language independently, so translations live here instead.
//
// To add a language:
//   1. Copy ar.js to <code>.js (e.g. ur.js) and translate the values.
//   2. Add an .import line and an entry in `catalogs` below.
// Strings missing from a catalog fall back to English.

.import "ar.js" as Ar

var catalogs = {
    en: { name: "English", locale: "en_US", strings: {} },
    ar: { name: "العربية", locale: "ar_SA", strings: Ar.strings }
};

// Resolve the configured language ("" = follow the system) to an available code.
function resolve(configured) {
    if (configured && catalogs[configured]) return configured;
    var langs = Qt.locale().uiLanguages;
    for (var i = 0; i < langs.length; i++) {
        var code = langs[i].split(/[-_]/)[0];
        if (catalogs[code]) return code;
    }
    return "en";
}

function locale(lang) {
    return Qt.locale(catalogs[lang] ? catalogs[lang].locale : "en_US");
}

// tr(lang, "in %1", [value]) -> "بعد ٥ د"
function tr(lang, text, args) {
    var cat = catalogs[lang];
    var out = (cat && cat.strings[text]) || text;
    if (args) {
        for (var i = 0; i < args.length; i++)
            out = out.split("%" + (i + 1)).join(String(args[i]));
    }
    return out;
}

// [{code, name}] for the language picker, "" first meaning automatic.
function languageList(autoLabel) {
    var list = [{ code: "", name: autoLabel }];
    for (var code in catalogs) list.push({ code: code, name: catalogs[code].name });
    return list;
}
