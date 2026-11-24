.pragma library

// SPDX-License-Identifier: GPL-3.0-or-later
// Prayer times calculation, adapted from the PrayTimes.org algorithm
// by Hamid Zarrabi-Zadeh (LGPL-3.0). Everything is computed locally; no network access needed.

var methods = {
    makkah:  { fajr: 18.5, ishaMinutes: 90 },   // Umm al-Qura, Makkah
    mwl:     { fajr: 18,   isha: 17 },          // Muslim World League
    isna:    { fajr: 15,   isha: 15 },          // ISNA (North America)
    egypt:   { fajr: 19.5, isha: 17.5 },        // Egyptian General Authority
    karachi: { fajr: 18,   isha: 18 },          // University of Islamic Sciences, Karachi
    gulf:    { fajr: 19.5, ishaMinutes: 90 },   // Gulf region
    kuwait:  { fajr: 18,   isha: 17.5 },        // Kuwait
    qatar:   { fajr: 18,   ishaMinutes: 90 },   // Qatar
    turkey:  { fajr: 18,   isha: 17 }           // Diyanet (approximation)
};

var order = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"];

function dtr(d) { return d * Math.PI / 180; }
function rtd(r) { return r * 180 / Math.PI; }
function sin(d) { return Math.sin(dtr(d)); }
function cos(d) { return Math.cos(dtr(d)); }
function tan(d) { return Math.tan(dtr(d)); }
function arcsin(x) { return rtd(Math.asin(x)); }
function arccos(x) { return rtd(Math.acos(x)); }
function arccot(x) { return rtd(Math.atan(1 / x)); }
function arctan2(y, x) { return rtd(Math.atan2(y, x)); }
function fix(a, b) { a = a - b * Math.floor(a / b); return a < 0 ? a + b : a; }

function julian(year, month, day) {
    if (month <= 2) { year -= 1; month += 12; }
    var A = Math.floor(year / 100);
    var B = 2 - A + Math.floor(A / 4);
    return Math.floor(365.25 * (year + 4716)) + Math.floor(30.6001 * (month + 1)) + day + B - 1524.5;
}

function sunPosition(jd) {
    var D = jd - 2451545.0;
    var g = fix(357.529 + 0.98560028 * D, 360);
    var q = fix(280.459 + 0.98564736 * D, 360);
    var L = fix(q + 1.915 * sin(g) + 0.020 * sin(2 * g), 360);
    var e = 23.439 - 0.00000036 * D;
    var RA = fix(arctan2(cos(e) * sin(L), cos(L)) / 15, 24);
    return { decl: arcsin(sin(e) * sin(L)), eqt: q / 15 - RA };
}

// Returns local times as fractional hours (may be NaN at extreme latitudes).
function computeHours(year, month, day, lat, lng, tz, methodKey, asrFactor) {
    var m = methods[methodKey] || methods.makkah;
    var jd = julian(year, month, day) - lng / (15 * 24);

    function midDay(t) { return fix(12 - sunPosition(jd + t).eqt, 24); }
    function angleTime(angle, t, ccw) {
        var decl = sunPosition(jd + t).decl;
        var T = arccos((-sin(angle) - sin(decl) * sin(lat)) / (cos(decl) * cos(lat))) / 15;
        return midDay(t) + (ccw ? -T : T);
    }
    function asrTime(factor, t) {
        var decl = sunPosition(jd + t).decl;
        return angleTime(-arccot(factor + tan(Math.abs(lat - decl))), t);
    }

    var h = { fajr: 5, sunrise: 6, dhuhr: 12, asr: 13, maghrib: 18, isha: 18 };
    for (var i = 0; i < 2; i++) {
        h = {
            fajr:    angleTime(m.fajr, h.fajr / 24, true),
            sunrise: angleTime(0.833, h.sunrise / 24, true),
            dhuhr:   midDay(h.dhuhr / 24),
            asr:     asrTime(asrFactor, h.asr / 24),
            maghrib: angleTime(0.833, h.maghrib / 24),
            isha:    m.isha !== undefined ? angleTime(m.isha, h.isha / 24) : h.isha
        };
    }
    var adj = tz - lng / 15;
    for (var k in h) h[k] += adj;
    if (m.ishaMinutes !== undefined) h.isha = h.maghrib + m.ishaMinutes / 60;
    return h;
}

// Returns [{key, date}] for the given day, with per-prayer minute offsets applied.
function computeDay(date, lat, lng, methodKey, asrFactor, offsets) {
    var y = date.getFullYear(), mo = date.getMonth(), d = date.getDate();
    var tz = -new Date(y, mo, d, 12).getTimezoneOffset() / 60;
    var h = computeHours(y, mo + 1, d, lat, lng, tz, methodKey, asrFactor);
    var out = [];
    for (var i = 0; i < order.length; i++) {
        var key = order[i];
        var mins = Math.round(h[key] * 60) + (offsets[key] || 0);
        out.push({ key: key, date: isNaN(mins) ? null : new Date(y, mo, d, 0, mins) });
    }
    return out;
}
