import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "singletons"

Panel {
    id: p
    name: "bat"
    // CPU / RAM / temperature, sampled only while this panel is open
    property real cpu: 0
    property real ram: 0
    property real temp: 0
    property var last: null
    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: p.open
        onTriggered: stat.running = true
    }
    onOpenChanged: if (!open) last = null
    Process {
        id: stat
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable)' /proc/meminfo; cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const L = text.trim().split("\n");
                if (L.length < 4) return;
                const c = L[0].trim().split(/\s+/).slice(1).map(Number);
                const idle = c[3] + c[4], total = c.reduce((a, b) => a + b, 0);
                if (p.last) { const dt = total - p.last[1]; if (dt > 0) p.cpu = 1 - (idle - p.last[0]) / dt; }
                p.last = [idle, total];
                const mt = parseInt(L[1].replace(/\D/g, "")), ma = parseInt(L[2].replace(/\D/g, ""));
                if (mt > 0) p.ram = 1 - ma / mt;
                p.temp = (parseInt(L[3]) || 0) / 1000;
            }
        }
    }
    readonly property var names: ({ "power-saver": "Saver", "balanced": "Balanced", "performance": "Performance" })

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: Sys.hasBattery ? Math.round(Sys.percent) + "%" : "AC"
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 30
            font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }
        Column {
            Layout.alignment: Qt.AlignVCenter
            Text {
                anchors.right: parent.right
                text: !Sys.hasBattery ? "No battery" : Sys.charging ? (Sys.percent >= 99 ? "Fully charged" : "Charging") : "On battery"
                color: Theme.fg; font.family: Theme.font; font.pixelSize: 13
            }
            Text {
                anchors.right: parent.right
                visible: Sys.eta() !== ""
                text: Sys.eta() + (Sys.charging ? " until full" : " remaining")
                color: Theme.dim; font.family: Theme.font; font.pixelSize: 11
            }
        }
    }
    Rectangle {
        visible: Sys.hasBattery
        Layout.fillWidth: true
        height: 8; radius: 4
        color: Qt.rgba(1, 1, 1, 0.10)
        Rectangle {
            width: parent.width * Math.min(1, Sys.percent / 100)
            height: parent.height; radius: 4
            color: Sys.charging ? "#5fd38d" : Sys.percent < 20 ? Theme.danger : Theme.accent
            Behavior on width { NumberAnimation { duration: Theme.dur } }
        }
    }
    Text { text: "Power mode"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 12; Layout.topMargin: 6 }
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: Sys.profiles
            delegate: Btn {
                required property string modelData
                Layout.fillWidth: true
                text: p.names[modelData]
                filled: Sys.profile === modelData
                onClicked: Sys.setProfile(modelData)
            }
        }
    }
    Text { text: "System"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 12; Layout.topMargin: 6 }
    Repeater {
        model: [
            { n: "CPU", v: p.cpu, t: Math.round(p.cpu * 100) + "%" },
            { n: "Memory", v: p.ram, t: Math.round(p.ram * 100) + "%" },
            { n: "Temp", v: Math.min(1, p.temp / 100), t: Math.round(p.temp) + "\u00b0C" }
        ]
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 10
            Text { text: modelData.n; color: Theme.fg; font.family: Theme.font; font.pixelSize: 12; Layout.preferredWidth: 56 }
            Rectangle {
                Layout.fillWidth: true
                height: 6; radius: 3
                color: Qt.rgba(1, 1, 1, 0.10)
                Rectangle {
                    width: parent.width * modelData.v; height: parent.height; radius: 3
                    color: modelData.v > 0.85 ? Theme.danger : Theme.accent
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }
            Text { text: modelData.t; color: Theme.dim; font.family: Theme.font; font.pixelSize: 12; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 40 }
        }
    }
}
