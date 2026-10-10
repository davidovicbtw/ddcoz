pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification server + a small capped history (plain copies, so nothing keeps live objects around).
Singleton {
    id: root
    property bool dnd: false
    property int unread: 0
    readonly property alias history: hist
    readonly property alias server: srv
    readonly property int maxHistory: 40

    ListModel { id: hist }

    function clear() { hist.clear(); unread = 0; }
    function remove(i) { hist.remove(i); }

    NotificationServer {
        id: srv
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        onNotification: n => {
            hist.insert(0, {
                app: n.appName || "",
                summary: n.summary || "",
                body: n.body || "",
                icon: n.image || (n.appIcon ? Quickshell.iconPath(n.appIcon, true) : ""),
                stamp: Qt.formatDateTime(new Date(), "HH:mm"),
                critical: n.urgency === NotificationUrgency.Critical
            });
            if (hist.count > root.maxHistory) hist.remove(root.maxHistory, hist.count - root.maxHistory);
            root.unread++;
            n.tracked = !root.dnd || n.urgency === NotificationUrgency.Critical;
        }
    }
}
