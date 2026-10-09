import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import "singletons"

// Spotlight-style launcher that grows out of the logo bubble.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "ddcoz-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.launcher ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property string home: Quickshell.env("HOME")
    property bool linger: false
    property bool expanded: false
    property bool anim: false
    property rect origin: Qt.rect(0, 0, 24, 24)
    property var fileResults: []
    property string confirmKey: ""
    visible: Ui.launcher || linger

    Connections {
        target: Ui
        function onLauncherChanged() {
            if (Ui.launcher) {
                win.linger = true;
                win.anim = false;
                win.origin = Ui.logoRect;
                win.expanded = false;
                input.text = Ui.query; win.fileResults = []; win.confirmKey = ""; list.currentIndex = 0;
                Qt.callLater(() => { win.anim = true; win.expanded = true; input.forceActiveFocus(); });
            } else {
                win.expanded = false;
                hide.restart();
            }
        }
    }
    Timer { id: hide; interval: Theme.durSlow + 80; onTriggered: win.linger = false }

    // ---------- search ----------
    readonly property string q: input.text.trim()
    readonly property var actions: [
        { title: "Lock Screen", kw: "lock screen", icon: "", cmd: home + "/.local/bin/ddcoz-lock" },
        { title: "Sleep", kw: "sleep suspend", icon: "", cmd: "systemctl suspend" },
        { title: "Log Out", kw: "log out logout exit", icon: "", cmd: "hyprctl dispatch 'hl.dsp.exit()' || hyprctl dispatch exit", risky: true },
        { title: "Restart", kw: "restart reboot", icon: "", cmd: "systemctl reboot", risky: true },
        { title: "Shut Down", kw: "shut down shutdown poweroff", icon: "", cmd: "systemctl poweroff", risky: true }
    ]

    function sh(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'"; }

    function calc(text) {
        if (!/^[0-9+\-*\/%^().,\s]+$/.test(text) || !/[0-9]/.test(text) || !/[+\-*\/%^]/.test(text.replace(/^\s*-/, ""))) return null;
        try {
            const v = eval("(" + text.replace(/\^/g, "**").replace(/,/g, ".") + ")");
            if (typeof v !== "number" || !isFinite(v)) return null;
            return Number(v.toPrecision(12));
        } catch (e) { return null; }
    }

    function build(text, files) {
        const out = [];
        if (!text) return out;
        if (text.startsWith(">")) {
            const c = text.slice(1).trim();
            return c ? [{ kind: "run", title: c, sub: "Run in shell", icon: "", cmd: c }] : [];
        }
        const lower = text.toLowerCase();
        const r = calc(text);
        if (r !== null) out.push({ kind: "calc", title: String(r), sub: text + "  ·  Enter to copy", icon: "", copy: String(r) });

        const apps = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue;
            const n = e.name.toLowerCase();
            let s = -1;
            if (n.startsWith(lower)) s = 3;
            else if (n.indexOf(" " + lower) >= 0) s = 2;
            else if (n.indexOf(lower) >= 0) s = 1;
            else if ((e.genericName || "").toLowerCase().indexOf(lower) >= 0 || (e.keywords || []).join(" ").toLowerCase().indexOf(lower) >= 0) s = 0.5;
            if (s >= 0) apps.push({ e: e, s: s });
        }
        apps.sort((a, b) => (b.s - a.s) || a.e.name.localeCompare(b.e.name));
        for (const a of apps.slice(0, 4)) out.push({ kind: "app", title: a.e.name, sub: a.e.comment || a.e.genericName || "Application", entry: a.e });

        for (const a of actions)
            if (a.kw.indexOf(lower) >= 0 || a.title.toLowerCase().startsWith(lower))
                out.push({ kind: "action", title: a.title, sub: "System", icon: a.icon, cmd: a.cmd, risky: !!a.risky, key: a.title });

        for (const f of files) {
            const name = f.split("/").pop() || f;
            out.push({ kind: "file", title: name, sub: f.replace(home, "~"), icon: "", path: f });
        }

        if (/^(https?:\/\/\S+|www\.\S+|[a-z0-9-]+(\.[a-z0-9-]+)*\.(com|org|net|io|dev|app|tr|ai|co|me|gg|tv|xyz)(\/\S*)?)$/i.test(text)) {
            const u = /^https?:\/\//i.test(text) ? text : "https://" + text;
            out.push({ kind: "url", title: "Open " + text, sub: "Website", icon: "", url: u });
        }
        out.push({ kind: "web", title: "Search the web for “" + text + "”", sub: "Opens in your browser", icon: "", url: Config.search + encodeURIComponent(text) });
        return out;
    }
    readonly property var items: build(q, fileResults)

    onQChanged: { list.currentIndex = 0; confirmKey = ""; deb.restart(); }
    Timer { id: deb; interval: 200; onTriggered: win.searchFiles() }
    function searchFiles() {
        fd.running = false;
        if (q.length < 2 || q.startsWith(">") || calc(q) !== null) { fileResults = []; return; }
        fd.command = ["fd", "-a", "-d", "6", "--max-results", "60", "-i", q, home];
        fd.running = true;
    }
    Process {
        id: fd
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim() ? text.trim().split("\n") : [];
                l.sort((a, b) => a.length - b.length);
                win.fileResults = l.slice(0, 2);
            }
        }
    }

    function activate(it) {
        if (!it) return;
        if (it.risky && confirmKey !== it.key) { confirmKey = it.key; return; }
        Ui.launcher = false;
        switch (it.kind) {
        case "app": it.entry.execute(); break;
        case "calc": Sys.run("printf %s " + sh(it.copy) + " | wl-copy"); break;
        case "action": case "run": Sys.run(it.cmd); break;
        case "file": Sys.run("xdg-open " + sh(it.path)); break;
        case "url": case "web": Sys.run("xdg-open " + sh(it.url)); break;
        }
    }

    // ---------- UI ----------
    MouseArea { anchors.fill: parent; enabled: Ui.launcher; onPressed: Ui.launcher = false }

    Rectangle {
        id: card
        readonly property real fw: 640
        readonly property real listH: Math.min(win.items.length, 7) * 54
        readonly property real fh: 62 + (win.items.length > 0 ? 9 + listH + 8 : 0)
        x: win.expanded ? (win.width - fw) / 2 : win.origin.x
        y: win.expanded ? win.height * 0.17 : win.origin.y
        width: win.expanded ? fw : win.origin.width
        height: win.expanded ? fh : win.origin.height
        radius: win.expanded ? 30 : win.origin.height / 2
        color: win.expanded ? Theme.panel : Theme.bg
        border.width: 1
        border.color: Theme.border
        clip: true
        visible: Ui.launcher || win.linger

        Behavior on x { enabled: win.anim; NumberAnimation { duration: Theme.durSlow + 60; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
        Behavior on y { enabled: win.anim; NumberAnimation { duration: Theme.durSlow + 60; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
        Behavior on width { enabled: win.anim; NumberAnimation { duration: Theme.durSlow + 60; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
        Behavior on height { enabled: win.anim; NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }
        Behavior on radius { enabled: win.anim; NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutCubic } }
        Behavior on color { enabled: win.anim; ColorAnimation { duration: Theme.durSlow } }

        MouseArea { anchors.fill: parent }

        Item {
            id: content
            anchors.fill: parent
            opacity: win.expanded ? 1 : 0
            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation { duration: win.expanded ? Theme.dur * 0.4 : 0 }
                    NumberAnimation { duration: win.expanded ? Theme.dur : 80 }
                }
            }

            Text {
                x: 26; y: 0; height: 62
                verticalAlignment: Text.AlignVCenter
                text: ""
                font.family: Theme.icons; font.pixelSize: 18
                color: Theme.dim
            }
            TextInput {
                id: input
                x: 62; y: 0
                width: parent.width - 62 - 26
                height: 62
                verticalAlignment: Text.AlignVCenter
                color: Theme.fg
                font.family: Theme.font; font.pixelSize: 20
                selectByMouse: true
                clip: true
                onAccepted: win.activate(win.items[list.currentIndex])
                Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
                Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
                Keys.onTabPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
                Keys.onEscapePressed: Ui.launcher = false
                Text {
                    visible: !input.text
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search apps, files, math, the web…"
                    color: Qt.rgba(1, 1, 1, 0.35)
                    font: input.font
                }
            }
            Rectangle {
                x: 20; y: 62
                width: parent.width - 40; height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
                opacity: win.items.length > 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
            ListView {
                id: list
                x: 8; y: 71
                width: parent.width - 16
                height: card.listH
                clip: true
                model: win.items
                currentIndex: 0
                highlightMoveDuration: 90
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    id: d
                    required property var modelData
                    required property int index
                    readonly property bool sel: list.currentIndex === index
                    width: list.width
                    height: 54
                    radius: 18
                    color: sel ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                    Behavior on color { ColorAnimation { duration: 90 } }

                    Rectangle {
                        id: tile
                        x: 10; width: 36; height: 36; radius: 11
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData.kind === "app" ? "transparent" : Qt.rgba(1, 1, 1, 0.08)
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 32
                            visible: modelData.kind === "app"
                            source: modelData.kind === "app" ? Quickshell.iconPath(modelData.entry.icon, "application-x-executable") : ""
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: modelData.kind !== "app"
                            text: modelData.icon || ""
                            font.family: Theme.icons; font.pixelSize: 16
                            color: modelData.kind === "calc" || d.sel ? Theme.accent : Theme.fg
                        }
                    }
                    Column {
                        anchors { left: tile.right; leftMargin: 12; right: hint.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        Text {
                            width: parent.width; elide: Text.ElideRight
                            text: modelData.title
                            color: Theme.fg; font.family: Theme.font
                            font.pixelSize: modelData.kind === "calc" ? 20 : 14
                            font.weight: Font.Medium
                        }
                        Text {
                            width: parent.width; elide: Text.ElideMiddle
                            text: modelData.risky && win.confirmKey === modelData.key ? "Press Enter again to confirm" : modelData.sub
                            color: modelData.risky && win.confirmKey === modelData.key ? Theme.danger : Theme.dim
                            font.family: Theme.font; font.pixelSize: 11
                        }
                    }
                    Text {
                        id: hint
                        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                        text: d.sel ? "↵" : ""
                        color: Theme.dim; font.pixelSize: 16
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: list.currentIndex = index
                        onClicked: win.activate(modelData)
                    }
                }
            }
        }
    }
}
