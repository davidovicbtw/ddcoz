pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool enabled: true
    property string ssid: ""
    property int signal: 0
    property bool wired: false
    property bool busy: false
    property string error: ""
    property var networks: []
    property var known: []
    readonly property bool connected: ssid !== "" || wired

    function refresh() { statusProc.running = true; }
    function scan() { rescanProc.running = true; listProc.running = true; knownProc.running = true; }
    function toggle() { radioProc.command = ["nmcli", "radio", "wifi", enabled ? "off" : "on"]; radioProc.running = true; }
    function connectTo(name, password) {
        if (connProc.running) return;
        error = ""; busy = true;
        if (password) connProc.command = ["nmcli", "dev", "wifi", "connect", name, "password", password];
        else if (known.indexOf(name) >= 0) connProc.command = ["nmcli", "connection", "up", "id", name];
        else connProc.command = ["nmcli", "dev", "wifi", "connect", name];
        connProc.running = true;
    }
    function disconnect() { discProc.running = true; }
    function isKnown(name) { return known.indexOf(name) >= 0; }

    function split(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length) { cur += line[++i]; }
            else if (c === ":") { out.push(cur); cur = ""; }
            else cur += c;
        }
        out.push(cur);
        return out;
    }

    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    Process {
        id: statusProc
        command: ["sh", "-c", "nmcli radio wifi; nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi list --rescan no | grep '^yes' | head -1; nmcli -t -f TYPE,STATE dev | grep -c '^ethernet:connected'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                root.enabled = l[0] === "enabled";
                const w = l.length > 2 ? root.split(l[1]) : null;
                root.ssid = w && w[0] === "yes" ? w[1] : "";
                root.signal = w && w[0] === "yes" ? parseInt(w[2]) || 0 : 0;
                root.wired = parseInt(l[l.length - 1]) > 0;
            }
        }
    }
    Process { id: rescanProc; command: ["nmcli", "dev", "wifi", "rescan"] }
    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const best = {};
                for (const line of text.trim().split("\n")) {
                    if (!line) continue;
                    const f = root.split(line);
                    if (!f[1]) continue;
                    const n = { ssid: f[1], signal: parseInt(f[2]) || 0, secure: f[3] !== "" && f[3] !== "--", active: f[0] === "yes" };
                    const o = best[n.ssid];
                    if (!o || n.active || (!o.active && n.signal > o.signal)) best[n.ssid] = n;
                }
                root.networks = Object.values(best).sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
            }
        }
    }
    Process {
        id: knownProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.known = text.trim().split("\n").map(l => root.split(l)).filter(f => f[1] === "802-11-wireless").map(f => f[0])
        }
    }
    Process {
        id: connProc
        stderr: StdioCollector { id: connErr }
        stdout: StdioCollector { id: connOut }
        onExited: code => {
            root.busy = false;
            root.error = code === 0 ? "" : ((connErr.text || connOut.text).trim().split("\n")[0] || "Connection failed");
            root.refresh(); root.scan();
        }
    }
    Process { id: radioProc; onExited: { root.refresh(); root.scan(); } }
    Process { id: discProc; command: ["sh", "-c", "nmcli -t -f DEVICE,TYPE dev | grep ':wifi' | cut -d: -f1 | xargs -r nmcli dev disconnect"]; onExited: root.refresh() }
}
