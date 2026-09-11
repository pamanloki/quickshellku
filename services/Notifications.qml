pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Notification daemon. Registers as the desktop notification server, feeds the
// transient toast layer (trackedNotifications), and keeps a persistent history
// (plain copies) for the Notification Center — copies survive after a toast is
// dismissed and the server frees the live Notification object.
Singleton {
    id: root

    // Live, tracked notifications → toasts.
    readonly property var list: server.trackedNotifications
    property bool doNotDisturb: false

    // History for the Notification Center (newest first), and an unread counter
    // reset when the center is opened.
    property var history: []
    property int unread: 0
    property int _seq: 0
    readonly property int maxHistory: 50

    function _push(n) {
        const entry = {
            id: ++root._seq,
            appName: n.appName || "Notification",
            summary: n.summary || "",
            body: n.body || "",
            appIcon: n.appIcon || "",
            image: n.image || "",
            urgency: n.urgency,
            time: Date.now()
        };
        const h = root.history.slice();
        h.unshift(entry);
        if (h.length > root.maxHistory)
            h.length = root.maxHistory;
        root.history = h;
        root.unread = root.unread + 1;
    }

    function clearHistory() { root.history = []; root.unread = 0; }
    function removeHistory(id) { root.history = root.history.filter(e => e.id !== id); }
    function markRead() { root.unread = 0; }

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: true

        onNotification: notification => {
            root._push(notification);           // always log to history
            if (root.doNotDisturb) {
                notification.expire();          // …but no toast while DND is on
                return;
            }
            notification.tracked = true;        // keep for the toast layer
        }
    }
}
