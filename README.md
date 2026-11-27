# Prayer Times & Adhan for KDE Plasma 6

**أوقات الصلاة والأذان لسطح مكتب KDE Plasma 6**

A panel widget that shows the next prayer and a live countdown, with optional adhan alerts.
Times are calculated locally from your coordinates — no internet connection or API needed.

ويدجت لسطح مكتب KDE Plasma 6 يعرض الصلاة القادمة والوقت المتبقي عليها، مع تنبيه بالأذان.
يحسب الأوقات على جهازك من الإحداثيات، بدون إنترنت.

## Features

- Next prayer + countdown in the panel; full day's times in the popup
- 9 calculation methods (Umm al-Qura, MWL, Egypt, Karachi, ISNA, Gulf, Kuwait, Qatar, Turkey), Standard/Hanafi Asr
- Per-prayer minute adjustments to match your local mosque
- Notifications at prayer time, optional reminder before it
- Your own adhan file (separate one for Fajr), play in full or only the first N seconds with fade-out
- Pauses playing music/videos when the adhan starts and resumes them after 2 minutes (configurable)
- Respects Do Not Disturb (with an option to override)
- Arabic and English, selectable independently of the system language

## Install

**From the KDE Store:** right-click the panel → *Add or Manage Widgets* → *Get New* → search "Prayer Times and Adhan",
or get it from the [store page](https://store.kde.org/p/2382635/).

**From a file:** download `prayer-times.plasmoid` from the [releases page](https://github.com/a7madi/prayer-times-kde-plasma/releases), then
*Add or Manage Widgets* → *Get New* → *Install Widget From Local File…*, or:

```bash
kpackagetool6 -t Plasma/Applet -i prayer-times.plasmoid
```

**From source:**

```bash
git clone https://github.com/a7madi/prayer-times-kde-plasma.git
kpackagetool6 -t Plasma/Applet -i prayer-times-kde-plasma   # first install
kpackagetool6 -t Plasma/Applet -u prayer-times-kde-plasma   # update
systemctl --user restart plasma-plasmashell                 # reload the panel
```

Then open the widget settings and enter your latitude and longitude (the default is Makkah).

Requires KDE Plasma 6.

## طريقة التثبيت

**من متجر KDE (الأسهل):** اضغط بالزر الأيمن على شريط المهام ← *Add or Manage Widgets* ← *Get New* ← ابحث عن «Prayer Times and Adhan».
أو من [صفحة الويدجت في المتجر](https://store.kde.org/p/2382635/).

**من ملف:** نزّل ملف `prayer-times.plasmoid` من [صفحة الإصدارات](https://github.com/a7madi/prayer-times-kde-plasma/releases)، وبعدها:
*Add or Manage Widgets* ← *Get New* ← *Install Widget From Local File…* واختر الملف. أو من الطرفية:

```bash
kpackagetool6 -t Plasma/Applet -i prayer-times.plasmoid
```

**من الكود المصدري:**

```bash
git clone https://github.com/a7madi/prayer-times-kde-plasma.git
kpackagetool6 -t Plasma/Applet -i prayer-times-kde-plasma   # أول تثبيت
kpackagetool6 -t Plasma/Applet -u prayer-times-kde-plasma   # تحديث
systemctl --user restart plasma-plasmashell                 # إعادة تشغيل الشريط
```

بعد إضافة الويدجت للشريط، اضغط عليه بالزر الأيمن ← *Configure* وأدخل خط العرض والطول لمدينتك (الافتراضي مكة).
ولو كان وضع «عدم الإزعاج» مفعّلاً عندك وتبي تسمع الأذان، فعّل خيار «شغّل الصوت حتى في وضع عدم الإزعاج» من صفحة التنبيهات.

يتطلب KDE Plasma 6.

## Adding a translation

Translations are plain JavaScript dictionaries in [`contents/ui/translations/`](contents/ui/translations/):

1. Copy `ar.js` to `<language-code>.js` (for example `ur.js`) and translate the values. Keep `%1`, `%2` placeholders.
2. Register it in `Translations.js`: add `.import "ur.js" as Ur` and an entry in `catalogs`
   with the language's native name and a Qt locale (for example `ur_PK`).
3. Optionally add `Name[ur]` / `Description[ur]` to `metadata.json`.

Missing strings fall back to English. Pull requests welcome.

## Credits

Prayer time calculation adapted from the [PrayTimes.org](http://praytimes.org) algorithm by Hamid Zarrabi-Zadeh.

## License

GPL-3.0-or-later
