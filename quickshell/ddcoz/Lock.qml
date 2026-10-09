import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// Session lock (ext-session-lock) with the ddcoz look. `demo` shows the same UI in a
// normal overlay window instead (for testing; still authenticates through PAM).
Scope {
    id: root
    property bool demo: false
    property string wallpaper: ""
    property string message: ""
    property bool busy: false
    property bool unlocking: false
    readonly property string user: Quickshell.env("USER")
    readonly property bool active: lock.locked || demo

    function lockNow() {
        if (active) return;
        unlocking = false; message = "";
        wpFile.reload();
        lock.locked = true;
    }
    function showDemo() { if (!active) { unlocking = false; message = ""; wpFile.reload(); demo = true; } }
    function finish() { lock.locked = false; demo = false; busy = false; unlocking = false; message = ""; }

    FileView {
        id: wpFile
        path: Quickshell.env("HOME") + "/.config/ddcoz/wallpaper"
        onLoaded: root.wallpaper = text().trim()
    }

    property string pending: ""
    property int failTick: 0
    PamContext {
        id: pam
        config: "hyprlock"
        user: root.user
        onPamMessage: { if (responseRequired) respond(root.pending); }
        onCompleted: result => {
            root.pending = "";
            root.busy = false;
            if (result === PamResult.Success) root.unlocking = true;
            else root.failTick++;
        }
        onError: { root.busy = false; root.failTick++; }
    }
    function tryPassword(pw) {
        if (busy || unlocking || pw.length === 0) return;
        busy = true; pending = pw; pam.start();
    }

    WlSessionLock {
        id: lock
        locked: false
        WlSessionLockSurface {
            color: "#0c0d12"
            LockView {
                id: view
                anchors.fill: parent
                wallpaper: root.wallpaper
                user: root.user
                busy: root.busy
                onSubmit: pw => root.tryPassword(pw)
                onGone: root.finish()
                Connections { target: root; function onFailTickChanged() { view.fail(); } function onUnlockingChanged() { if (root.unlocking) view.leave(); } }
            }
        }
    }

    Variants {
        model: root.demo ? Quickshell.screens : []
        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "black"
            WlrLayershell.namespace: "ddcoz-lock-demo"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            LockView {
                id: dview
                anchors.fill: parent
                demo: true
                wallpaper: root.wallpaper
                user: root.user
                busy: root.busy
                onSubmit: pw => root.tryPassword(pw)
                onDismissed: dview.leave()
                onGone: root.finish()
                Connections { target: root; function onFailTickChanged() { dview.fail(); } function onUnlockingChanged() { if (root.unlocking) dview.leave(); } }
            }
        }
    }
}
