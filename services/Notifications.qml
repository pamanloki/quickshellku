pragma Singleton

import Quickshell
import Quickshell.Services.Notifications

// Notification daemon. Registers as the desktop notification server and keeps
// incoming notifications tracked so the toast layer can show them.
Singleton {
    id: root

    // Tracked notifications (those we chose to keep showing).
    readonly property var list: server.trackedNotifications
    property bool doNotDisturb: false

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: true

        onNotification: notification => {
            if (root.doNotDisturb) {
                notification.expire();
                return;
            }
            // Keep it around so it appears in trackedNotifications for the toasts.
            notification.tracked = true;
        }
    }
}
