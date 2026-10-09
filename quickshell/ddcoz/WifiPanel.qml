import QtQuick
import QtQuick.Layouts
import "singletons"

Panel {
    id: p
    name: "wifi"
    property string expanded: ""
    onOpened: { expanded = ""; Net.refresh(); Net.scan(); }

    RowLayout {
        Layout.fillWidth: true
        Text { text: "Wi‑Fi"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true }
        Tog { on: Net.enabled; onToggled: Net.toggle() }
    }
    Text {
        visible: Net.error !== ""
        Layout.fillWidth: true
        text: Net.error
        wrapMode: Text.WordWrap
        color: Theme.danger
        font.family: Theme.font
        font.pixelSize: 11
    }
    Text {
        visible: !Net.enabled
        text: "Wi‑Fi is turned off"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 12
    }
    ListView {
        id: lv
        visible: Net.enabled
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 280)
        clip: true
        spacing: 2
        model: Net.networks
        boundsBehavior: Flickable.StopAtBounds
        delegate: Item {
            id: d
            required property var modelData
            readonly property bool open: p.expanded === modelData.ssid
            width: lv.width
            height: open ? 92 : 44
            Behavior on height { NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic } }
            clip: true
            Row2 {
                width: parent.width
                height: 44
                icon: ""
                iconColor: modelData.active ? Theme.accent : Qt.rgba(1, 1, 1, 0.3 + modelData.signal / 150)
                title: modelData.ssid
                subtitle: modelData.active ? (Net.busy ? "Connecting…" : "Connected") : Net.isKnown(modelData.ssid) ? "Saved" : modelData.secure ? "Secured" : "Open"
                trailing: modelData.active ? "" : modelData.secure ? "" : ""
                highlighted: modelData.active
                onClicked: {
                    if (modelData.active) { Net.disconnect(); return; }
                    if (modelData.secure && !Net.isKnown(modelData.ssid)) {
                        p.expanded = d.open ? "" : modelData.ssid;
                        if (!d.open) pw.focusInput();
                    } else Net.connectTo(modelData.ssid, "");
                }
            }
            RowLayout {
                y: 48
                width: parent.width - 8
                x: 4
                spacing: 8
                Field {
                    id: pw
                    Layout.fillWidth: true
                    password: true
                    placeholder: "Password"
                    onAccepted: { Net.connectTo(modelData.ssid, text); text = ""; p.expanded = ""; }
                }
                Btn { text: "Join"; filled: true; onClicked: { Net.connectTo(modelData.ssid, pw.text); pw.text = ""; p.expanded = ""; } }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Btn { text: "Scan"; icon: ""; onClicked: Net.scan() }
        Item { Layout.fillWidth: true }
        Btn { text: "Settings"; icon: ""; onClicked: { Ui.close(); Sys.run(Config.terminal + " -e nmtui"); } }
    }
}
