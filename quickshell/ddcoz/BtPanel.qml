import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "singletons"

Panel {
    id: p
    name: "bt"
    readonly property var ad: Bluetooth.defaultAdapter
    onOpened: if (ad && ad.enabled) ad.discovering = true
    onOpenChanged: if (!open && ad) ad.discovering = false

    function glyph(ic) {
        if (!ic) return "";
        if (ic.indexOf("headset") >= 0 || ic.indexOf("headphone") >= 0) return "";
        if (ic.indexOf("keyboard") >= 0) return "";
        if (ic.indexOf("mouse") >= 0) return "";
        if (ic.indexOf("phone") >= 0) return "";
        if (ic.indexOf("audio") >= 0) return "";
        return "";
    }

    RowLayout {
        Layout.fillWidth: true
        Text { text: "Bluetooth"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true }
        Tog {
            on: p.ad ? p.ad.enabled : false
            onToggled: if (p.ad) { p.ad.enabled = !p.ad.enabled; p.ad.discovering = p.ad.enabled; }
        }
    }
    Text {
        visible: !p.ad
        text: "No Bluetooth adapter found"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 12
    }
    Text {
        visible: p.ad && !p.ad.enabled
        text: "Bluetooth is turned off"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 12
    }
    ListView {
        id: lv
        visible: p.ad && p.ad.enabled
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 280)
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: p.ad ? p.ad.devices : null
        delegate: Row2 {
            required property var modelData
            width: lv.width
            visible: modelData.paired || (modelData.name && modelData.name !== modelData.address.replace(/:/g, "-"))
            height: visible ? 44 : 0
            icon: p.glyph(modelData.icon)
            iconColor: modelData.connected ? Theme.accent : Theme.fg
            title: modelData.name || modelData.address
            subtitle: modelData.pairing ? "Pairing…" : modelData.connected ? "Connected" : modelData.paired ? "Paired" : "Available"
            trailing: modelData.batteryAvailable ? Math.round(modelData.battery * (modelData.battery <= 1 ? 100 : 1)) + "%" : ""
            highlighted: modelData.connected
            onClicked: {
                if (modelData.connected) modelData.disconnect();
                else if (modelData.paired) modelData.connect();
                else modelData.pair();
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Btn {
            text: p.ad && p.ad.discovering ? "Scanning…" : "Scan"
            icon: ""
            filled: p.ad && p.ad.discovering
            onClicked: if (p.ad) p.ad.discovering = !p.ad.discovering
        }
        Item { Layout.fillWidth: true }
        Btn { text: "Settings"; icon: ""; onClicked: { Ui.close(); Sys.run(Config.terminal + " -e bluetoothctl"); } }
    }
}
