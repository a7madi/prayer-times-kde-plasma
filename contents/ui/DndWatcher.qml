import QtQuick
import org.kde.notificationmanager as NotificationManager

// Loaded through a Loader so the widget keeps working if this
// Plasma-internal module ever changes or is missing.
QtObject {
    property NotificationManager.Settings settings: NotificationManager.Settings { live: true }

    function isActive() {
        const until = settings.notificationsInhibitedUntil;
        return settings.notificationsInhibitedByApplication
            || (until instanceof Date && !isNaN(until) && until > new Date());
    }
}
