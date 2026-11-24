import QtQuick
import org.kde.plasma.configuration
import "../ui/translations/Translations.js" as T

ConfigModel {
    ConfigCategory {
        name: T.tr(T.resolve(""), "General")
        icon: "preferences-system-time"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: T.tr(T.resolve(""), "Alerts")
        icon: "preferences-desktop-notification-bell"
        source: "configAlerts.qml"
    }
}
