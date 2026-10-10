import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import "singletons"

// Spotlight-style launcher that grows out of the logo bubble.
// Fuzzy + frecency app search, open-window switching, prefixes: "c " clipboard, "w " wallpapers, ">" shell.
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
    property var fileResults: []
    property var clipAll: []
    property bool clipLoaded: false
    property string confirmKey: ""
    visible: Ui.launcher || linger

    readonly property int rowH: 54
    readonly property int headH: 26
    readonly property int footH: 36

    Connections {
        target: Ui
        function onLauncherChanged() {
            if (Ui.launcher) {
                win.linger = true;
                win.anim = false;
                win.expanded = false;
                win.clipLoaded = false;
                if (Hyprland.refreshToplevels) Hyprland.refreshToplevels();
                input.text = Ui.query; win.fileResults = []; win.confirmKey = ""; list.currentIndex = 0;
                Qt.callLater(() => { win.anim = true; win.expanded = true; input.forceActiveFocus(); });
            } else {
                win.expanded = false;
                hide.restart();
            }
        }
    }
    Timer { id: hide; interval: 140; onTriggered: win.linger = false }
    
    // ---------- frecency ----------
    FileView { id: histFile; path: win.home + "/.config/ddcoz/launcher-history.json"; blockLoading: true; printErrors: false }
    property var hist: ({})
    Component.onCompleted: { try { hist = JSON.parse(histFile.text()) || {}; } catch (e) { hist = {}; } }
    function bump(id) {
        const h = Object.assign({}, hist);
        const o = h[id] || { n: 0, t: 0 };
        h[id] = { n: o.n + 1, t: Date.now() };
        hist = h;
        histFile.setText(JSON.stringify(h));
    }
    function frec(id) {
        const o = hist[id];
        if (!o) return 0;
        const days = (Date.now() - o.t) / 86400000;
        const rec = days < 1 ? 1.6 : days < 7 ? 1.2 : days < 30 ? 0.8 : 0.5;
        return Math.min(32, 11 * Math.log(1 + o.n) / Math.LN2 * rec);
    }

    // ---------- search ----------
    readonly property string raw: input.text
    readonly property string q: raw.trim()
    readonly property string mode: raw.startsWith(">") ? "run" : /^c\s/i.test(raw) ? "clip" : /^w\s/i.test(raw) ? "wall" : ""
    readonly property string arg: mode === "run" ? raw.slice(1).trim() : mode ? raw.slice(2).trim() : q
    readonly property string modeLabel: mode === "run" ? "Run command" : mode === "clip" ? "Clipboard" : mode === "wall" ? "Wallpapers" : ""
    readonly property string modeIcon: mode === "run" ? "" : mode === "clip" ? "" : mode === "wall" ? "" : ""

    readonly property var actions: [
        { title: "Lock Screen", kw: "lock screen", icon: "", cmd: home + "/.local/bin/ddcoz-lock" },
        { title: "Sleep", kw: "sleep suspend", icon: "", cmd: "systemctl suspend" },
        { title: "Change Wallpaper", kw: "wallpaper background", icon: "", fn: "wallpaper" },
        { title: "Clipboard History", kw: "clipboard history paste", icon: "", fn: "clipboard" },
        { title: "Log Out", kw: "log out logout exit", icon: "", cmd: "hyprctl dispatch 'hl.dsp.exit()' || hyprctl dispatch exit", risky: true },
        { title: "Restart", kw: "restart reboot", icon: "", cmd: "systemctl reboot", risky: true },
        { title: "Shut Down", kw: "shut down shutdown poweroff", icon: "", cmd: "systemctl poweroff", risky: true }
    ]

    function sh(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'"; }
    function addr(t) { return t.address.indexOf("0x") === 0 ? t.address : "0x" + t.address; }
    function winClass(t) { return t.lastIpcObject && t.lastIpcObject.class ? t.lastIpcObject.class : ""; }
    function winIcon(t) { return Quickshell.iconPath(winClass(t).toLowerCase(), "application-x-executable"); }

    function calc(text) {
        if (!/^[0-9+\-*\/%^().,\s]+$/.test(text) || !/[0-9]/.test(text) || !/[+\-*\/%^]/.test(text.replace(/^\s*-/, ""))) return null;
        try {
            const v = eval("(" + text.replace(/\^/g, "**").replace(/,/g, ".") + ")");
            if (typeof v !== "number" || !isFinite(v)) return null;
            return Number(v.toPrecision(12));
        } catch (e) { return null; }
    }

    // Returns { s: score, pos: matched char indexes } or null.
    function fuzzy(name, query) {
        const n = name.toLowerCase();
        const i = n.indexOf(query);
        if (i >= 0) {
            const pos = [];
            for (let k = 0; k < query.length; k++) pos.push(i + k);
            const wb = i === 0 || " -_.".indexOf(n[i - 1]) >= 0;
            return { s: (i === 0 ? 100 : wb ? 82 : 62) - Math.min(n.length - query.length, 30) * 0.4, pos: pos };
        }
        if (query.length < 2) return null;
        const pos = [];
        let from = 0, score = 0, last = -2;
        for (let qi = 0; qi < query.length; qi++) {
            const f = n.indexOf(query[qi], from);
            if (f < 0) return null;
            score += f === last + 1 ? 7 : 1;
            if (f === 0 || " -_.".indexOf(n[f - 1]) >= 0) score += 6;
            pos.push(f); last = f; from = f + 1;
        }
        if (pos[pos.length - 1] - pos[0] > query.length * 4) return null;
        return { s: Math.min(55, 15 + score), pos: pos };
    }

    function rich(title, pos) {
        if (!pos || !pos.length) return "";
        const set = {};
        for (const p of pos) set[p] = 1;
        let out = "";
        for (let i = 0; i < title.length; i++) {
            const c = title[i].replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
            out += set[i] ? "<b><font color=\"" + Theme.accent + "\">" + c + "</font></b>" : c;
        }
        return out;
    }

    function appItem(e, m) {
        return { kind: "app", group: "Applications", title: e.name, rich: m ? rich(e.name, m.pos) : "", sub: e.comment || e.genericName || "Application",
                 entry: e, hid: "app:" + e.id, iconSrc: Quickshell.iconPath(e.icon, "application-x-executable") };
    }
    function winItem(t, m) {
        const cls = winClass(t);
        const title = t.title || cls || "Window";
        return { kind: "win", group: "Open windows", title: title, rich: m ? rich(title, m.pos) : "", sub: (cls ? cls + "  ·  " : "") + "Switch to window",
                 addr: addr(t), iconSrc: winIcon(t) };
    }

    function build(text, files, clip) {
        const out = [];

        // ----- shell mode -----
        if (mode === "run")
            return arg ? [{ kind: "run", group: "", title: arg, sub: "Run in shell", icon: "", cmd: arg }] : [];

        // ----- clipboard mode -----
        if (mode === "clip") {
            const f = arg.toLowerCase();
            const hits = f ? clip.filter(e => e.text.toLowerCase().indexOf(f) >= 0) : clip;
            for (const e of hits.slice(0, 40))
                out.push({ kind: "clip", group: "Clipboard", title: e.text, sub: e.image ? "Image  ·  Enter to copy" : "Enter to copy", icon: e.image ? "" : "", cid: e.id });
            if (!out.length) out.push({ kind: "none", group: "", title: clipLoaded && !clip.length ? "Clipboard is empty" : "No matching clips", sub: "", icon: "" });
            return out;
        }

        // ----- wallpaper mode -----
        if (mode === "wall")
            return [{ kind: "wall", group: "", title: arg ? "Search wallpapers for “" + arg + "”" : "Browse wallpapers", sub: "Opens the wallpaper picker", icon: "", wq: arg }];

        // ----- empty: recents + open windows -----
        if (!text) {
            const rec = [];
            for (const e of DesktopEntries.applications.values) {
                if (e.noDisplay) continue;
                const fr = frec("app:" + e.id);
                if (fr > 0) rec.push({ e: e, fr: fr });
            }
            rec.sort((a, b) => b.fr - a.fr);
            for (const r of rec.slice(0, 5)) { const it = appItem(r.e, null); it.group = "Recent"; out.push(it); }
            for (const t of Hyprland.toplevels.values.slice(0, 4)) out.push(winItem(t, null));
            return out;
        }

        const lower = text.toLowerCase();
        const r = calc(text);
        if (r !== null) out.push({ kind: "calc", group: "", title: String(r), sub: text + "  ·  Enter to copy", icon: "", copy: String(r) });

        const apps = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue;
            let m = fuzzy(e.name, lower);
            let s = m ? m.s : -1;
            if (s < 0) {
                const extra = ((e.genericName || "") + " " + (e.keywords || []).join(" ") + " " + (e.comment || "")).toLowerCase();
                if (extra.indexOf(lower) >= 0) s = 24;
            }
            if (s < 0) continue;
            apps.push({ e: e, m: m, s: s + frec("app:" + e.id) });
        }
        apps.sort((a, b) => (b.s - a.s) || a.e.name.localeCompare(b.e.name));
        for (const a of apps.slice(0, 5)) out.push(appItem(a.e, a.m));

        const wins = [];
        for (const t of Hyprland.toplevels.values) {
            const m1 = fuzzy(t.title || "", lower), m2 = fuzzy(winClass(t), lower);
            const m = m1 && m2 ? (m1.s >= m2.s ? m1 : m2) : (m1 || m2);
            if (m && m.s >= 40) wins.push({ t: t, m: m === m2 ? null : m, s: m.s });
        }
        wins.sort((a, b) => b.s - a.s);
        for (const w of wins.slice(0, 3)) out.push(winItem(w.t, w.m));

        for (const a of actions)
            if (a.kw.indexOf(lower) >= 0 || a.title.toLowerCase().startsWith(lower))
                out.push({ kind: "action", group: "System", title: a.title, sub: a.risky ? "Needs confirmation" : "System", icon: a.icon, cmd: a.cmd, fn: a.fn, risky: !!a.risky, key: a.title });

        for (const f of files) {
            const name = f.split("/").pop() || f;
            out.push({ kind: "file", group: "Files", title: name, sub: f.replace(home, "~"), icon: "", path: f });
        }

        if (/^(https?:\/\/\S+|www\.\S+|[a-z0-9-]+(\.[a-z0-9-]+)*\.(com|org|net|io|dev|app|tr|ai|co|me|gg|tv|xyz)(\/\S*)?)$/i.test(text)) {
            const u = /^https?:\/\//i.test(text) ? text : "https://" + text;
            out.push({ kind: "url", group: "Web", title: "Open " + text, sub: "Website", icon: "", url: u });
        }
        out.push({ kind: "web", group: "Web", title: "Search the web for “" + text + "”", sub: "Opens in your browser", icon: "", url: Config.search + encodeURIComponent(text) });
        return out;
    }
    readonly property var items: build(q, fileResults, clipAll)

    readonly property real listContentH: {
        let h = 0, last = null;
        for (const it of items) {
            if (it.group && it.group !== last) h += headH;
            last = it.group;
            h += rowH;
        }
        return h;
    }

    onRawChanged: {
        list.currentIndex = 0; confirmKey = ""; deb.restart();
        if (mode === "clip" && !clipLoaded) { clipLoaded = true; clipProc.running = true; }
    }
    Timer { id: deb; interval: 200; onTriggered: win.searchFiles() }
    function searchFiles() {
        fd.running = false;
        if (mode || q.length < 2 || calc(q) !== null) { fileResults = []; return; }
        fd.command = ["fd", "-a", "-d", "6", "--max-results", "60", "-i", q, home];
        fd.running = true;
    }
    Process {
        id: fd
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim() ? text.trim().split("\n") : [];
                l.sort((a, b) => a.length - b.length);
                win.fileResults = l.slice(0, 3);
            }
        }
    }
    Process {
        id: clipProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const t = line.indexOf("\t");
                    if (t < 1) continue;
                    const id = parseInt(line.slice(0, t));
                    const body = line.slice(t + 1);
                    const img = /^\[\[ binary data (.*?) (png|jpg|jpeg|bmp|webp|gif) /.exec(body);
                    out.push({ id: id, text: img ? "Image  ·  " + img[1] + " " + img[2] : body.replace(/\s+/g, " ").trim(), image: !!img });
                    if (out.length >= 150) break;
                }
                win.clipAll = out;
            }
        }
    }

    function activate(it) {
        if (!it || it.kind === "none") return;
        if (it.risky && confirmKey !== it.key) { confirmKey = it.key; return; }
        Ui.launcher = false;
        switch (it.kind) {
        case "app": bump(it.hid); it.entry.execute(); break;
        case "win": Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + it.addr + "\" })"); break;
        case "calc": Sys.run("printf %s " + sh(it.copy) + " | wl-copy"); break;
        case "clip": Sys.run("cliphist decode " + it.cid + " | wl-copy"); break;
        case "wall": Ui.wallQuery = it.wq; Ui.closeAll(); Ui.wallpaper = true; break;
        case "action":
            if (it.fn === "wallpaper") { Ui.wallQuery = ""; Ui.closeAll(); Ui.wallpaper = true; }
            else if (it.fn === "clipboard") { Ui.closeAll(); Ui.clipboard = true; }
            else Sys.run(it.cmd);
            break;
        case "run": Sys.run(it.cmd); break;
        case "file": Sys.run("xdg-open " + sh(it.path)); break;
        case "url": case "web": Sys.run("xdg-open " + sh(it.url)); break;
        }
    }

    function move(d) { if (list.count > 0) list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + d)); }

    // ---------- UI ----------
    MouseArea { anchors.fill: parent; enabled: Ui.launcher; onPressed: Ui.launcher = false }

    Rectangle {
        id: card
        readonly property real fw: 660
        readonly property real listH: Math.min(win.listContentH, 7.5 * win.rowH)
        readonly property real fh: 62 + (win.items.length > 0 ? 9 + listH + 8 : 0) + win.footH
        x: (win.width - fw) / 2
        y: win.height * 0.17
        width: fw
        height: fh
        radius: 30
        color: Theme.panel
        border.width: 1
        border.color: Theme.border
        clip: true
        visible: Ui.launcher || win.linger

        // zoom-out + fade on open, reverse on close
        opacity: win.expanded ? 1 : 0
        scale: win.expanded ? 1 : 1.06
        transformOrigin: Item.Top
        Behavior on opacity { enabled: win.anim; NumberAnimation { duration: win.expanded ? 150 : 100; easing.type: Easing.OutCubic } }
        Behavior on scale { enabled: win.anim; NumberAnimation { duration: win.expanded ? 190 : 100; easing.type: Easing.OutCubic } }
        Behavior on height { enabled: win.anim && win.expanded; NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        Item {
            id: content
            anchors.fill: parent

            // ----- search row -----
            Text {
                id: sIcon
                x: 26; y: 0; height: 62
                verticalAlignment: Text.AlignVCenter
                text: win.modeIcon
                font.family: Theme.icons; font.pixelSize: 18
                color: win.mode ? Theme.accent : Theme.dim
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            TextInput {
                id: input
                x: 62; y: 0
                width: parent.width - 62 - 26 - (chip.visible ? chip.width + 10 : 0)
                height: 62
                verticalAlignment: Text.AlignVCenter
                color: Theme.fg
                font.family: Theme.font; font.pixelSize: 20
                selectByMouse: true
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentText
                clip: true
                cursorDelegate: Rectangle { width: 2; radius: 1; color: Theme.accent; visible: input.cursorVisible }
                onAccepted: win.activate(win.items[list.currentIndex])
                Keys.onUpPressed: win.move(-1)
                Keys.onDownPressed: win.move(1)
                Keys.onTabPressed: win.move(1)
                Keys.onBacktabPressed: win.move(-1)
                Keys.onEscapePressed: Ui.launcher = false
                Keys.onPressed: e => {
                    if (e.modifiers & Qt.ControlModifier) {
                        if (e.key === Qt.Key_J || e.key === Qt.Key_N) { win.move(1); e.accepted = true; }
                        else if (e.key === Qt.Key_K || e.key === Qt.Key_P) { win.move(-1); e.accepted = true; }
                    } else if (e.key === Qt.Key_PageDown) { win.move(5); e.accepted = true; }
                    else if (e.key === Qt.Key_PageUp) { win.move(-5); e.accepted = true; }
                }
                Text {
                    visible: !input.text
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search apps, windows, files, math, the web…"
                    color: Qt.rgba(1, 1, 1, 0.35)
                    font: input.font
                }
            }
            Rectangle {
                id: chip
                visible: opacity > 0.01
                opacity: win.mode ? 1 : 0
                anchors { right: parent.right; rightMargin: 22; top: parent.top; topMargin: 19 }
                height: 24; radius: 12
                width: chipText.implicitWidth + 22
                color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.12)
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: win.modeLabel || chipKeep
                    property string chipKeep: ""
                    onTextChanged: if (win.modeLabel) chipKeep = win.modeLabel
                    color: Theme.accent
                    font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold
                }
            }
            Rectangle {
                x: 20; y: 62
                width: parent.width - 40; height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
                opacity: win.items.length > 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // ----- results -----
            ListView {
                id: list
                x: 8; y: 71
                width: parent.width - 16
                height: card.listH
                clip: true
                model: win.items
                currentIndex: 0
                highlightMoveDuration: 90
                highlightMoveVelocity: -1
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: false

                section.property: "group"
                section.criteria: ViewSection.FullString
                section.delegate: Item {
                    required property string section
                    width: list.width
                    height: section ? win.headH : 0
                    visible: section !== ""
                    Text {
                        x: 16; y: 10
                        text: parent.section.toUpperCase()
                        color: Qt.rgba(1, 1, 1, 0.38)
                        font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold
                        font.letterSpacing: 1.2
                    }
                }

                highlight: Rectangle {
                    radius: 18
                    color: Qt.rgba(1, 1, 1, 0.10)
                    Rectangle {
                        x: 5; width: 3; height: 20; radius: 1.5
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.accent
                    }
                }

                delegate: Item {
                    id: d
                    required property var modelData
                    required property int index
                    readonly property bool sel: list.currentIndex === index
                    width: list.width
                    height: win.rowH

                    Item {
                        id: tile
                        x: 10; width: 36; height: 36
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            anchors.fill: parent; radius: 11
                            visible: !d.modelData.iconSrc
                            color: d.sel && d.modelData.kind !== "none" ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.07)
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 32
                            visible: !!d.modelData.iconSrc
                            source: d.modelData.iconSrc || ""
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: !d.modelData.iconSrc
                            text: d.modelData.icon || ""
                            font.family: Theme.icons; font.pixelSize: 16
                            color: d.modelData.kind === "calc" || d.sel ? Theme.accent : Theme.fg
                        }
                    }
                    Column {
                        anchors { left: tile.right; leftMargin: 12; right: hint.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        Text {
                            width: parent.width; elide: Text.ElideRight
                            textFormat: d.modelData.rich ? Text.StyledText : Text.PlainText
                            text: d.modelData.rich || d.modelData.title
                            color: d.modelData.kind === "calc" ? Theme.accent : Theme.fg
                            font.family: Theme.font
                            font.pixelSize: d.modelData.kind === "calc" ? 20 : 14
                            font.weight: Font.Medium
                        }
                        Text {
                            width: parent.width; elide: Text.ElideMiddle
                            visible: text !== ""
                            text: d.modelData.risky && win.confirmKey === d.modelData.key ? "Press Enter again to confirm" : d.modelData.sub
                            color: d.modelData.risky && win.confirmKey === d.modelData.key ? Theme.danger : Theme.dim
                            font.family: Theme.font; font.pixelSize: 11
                        }
                    }
                    Text {
                        id: hint
                        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                        text: d.sel && d.modelData.kind !== "none" ? "↵" : ""
                        color: Theme.dim; font.pixelSize: 16
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onPositionChanged: list.currentIndex = d.index
                        onClicked: win.activate(d.modelData)
                    }
                }
            }

            // ----- footer hints -----
            Item {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: win.footH
                Rectangle {
                    x: 20; y: 0; width: parent.width - 40; height: 1
                    color: Qt.rgba(1, 1, 1, 0.06)
                }
                Row {
                    x: 22; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 1
                    spacing: 14
                    Repeater {
                        model: [{ k: "↑↓", l: "navigate" }, { k: "↵", l: "open" }, { k: "esc", l: "close" }]
                        delegate: Row {
                            required property var modelData
                            spacing: 6
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 18; width: Math.max(18, kt.implicitWidth + 10); radius: 6
                                color: Qt.rgba(1, 1, 1, 0.08)
                                Text { id: kt; anchors.centerIn: parent; text: modelData.k; color: Theme.dim; font.family: Theme.font; font.pixelSize: 10 }
                            }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.l; color: Qt.rgba(1, 1, 1, 0.38); font.family: Theme.font; font.pixelSize: 11 }
                        }
                    }
                }
                Text {
                    anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter; verticalCenterOffset: 1 }
                    opacity: win.q === "" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    text: "c  clipboard    w  wallpapers    >  run"
                    color: Qt.rgba(1, 1, 1, 0.38)
                    font.family: Theme.font; font.pixelSize: 11
                }
            }
        }
    }
}
