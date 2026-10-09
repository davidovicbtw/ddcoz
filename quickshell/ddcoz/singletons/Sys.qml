pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: bat && bat.isLaptopBattery
    readonly property real percent: bat ? bat.percentage * (bat.percentage <= 1 ? 100 : 1) : 0
    readonly property bool charging: bat ? (bat.state === UPowerDeviceState.Charging || bat.state === UPowerDeviceState.FullyCharged) : false
    property string profile: "balanced"
    property var profiles: ["power-saver", "balanced", "performance"]

    function setProfile(p) { profProc.command = ["powerprofilesctl", "set", p]; profProc.running = true; profile = p; }
    function run(cmd) { runner.command = ["sh", "-c", cmd]; runner.running = true; }
    function lock() { run("$HOME/.local/bin/ddcoz-lock"); }
    function eta() {
        if (!bat) return "";
        const s = charging ? bat.timeToFull : bat.timeToEmpty;
        if (!s || s <= 0) return "";
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        return (h > 0 ? h + "h " : "") + m + "m";
    }

    Process {
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector { onStreamFinished: if (text.trim()) root.profile = text.trim() }
    }
    Process { id: profProc }
    Process { id: runner }
}
