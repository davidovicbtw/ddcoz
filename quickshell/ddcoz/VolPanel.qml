import QtQuick
import QtQuick.Layouts
import "singletons"

Panel {
    id: p
    name: "vol"
    function icon(v, m) { return m || v <= 0.001 ? "" : v < 0.4 ? "" : ""; }

    Text { text: "Sound"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 16; font.weight: Font.DemiBold }
    Slid {
        Layout.fillWidth: true
        icon: p.icon(Audio.volume, Audio.muted)
        value: Audio.muted ? 0 : Audio.volume
        onMoved: v => Audio.setVolume(v)
        onIconClicked: Audio.toggleMute()
    }
    Text { visible: Brightness.available; text: "Display"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 12; Layout.topMargin: 4 }
    Slid {
        visible: Brightness.available
        Layout.fillWidth: true
        icon: ""
        value: Brightness.value
        onMoved: v => Brightness.set(v)
    }
    Text { visible: Audio.sinks.length > 1; text: "Output"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 12; Layout.topMargin: 4 }
    Repeater {
        model: Audio.sinks.length > 1 ? Audio.sinks : []
        delegate: Row2 {
            required property var modelData
            Layout.fillWidth: true
            icon: ""
            title: Audio.name(modelData)
            trailing: modelData === Audio.sink ? "" : ""
            highlighted: modelData === Audio.sink
            onClicked: Audio.setSink(modelData)
        }
    }
    Btn { text: "Mixer"; icon: ""; Layout.topMargin: 2; onClicked: { Ui.close(); Sys.run("pavucontrol || " + Config.terminal + " -e wiremix"); } }
}
