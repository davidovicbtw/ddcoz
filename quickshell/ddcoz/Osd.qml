import QtQuick
import Quickshell
import Quickshell.Wayland
import "singletons"

// Volume / brightness pill. The window only exists while it is on screen (LazyLoader).
Scope {
    id: osd
    property bool up: false      // window exists
    property bool shown: false   // fade state
    property bool ready: false   // ignore the startup burst of value changes

    Timer { interval: 2500; running: true; onTriggered: osd.ready = true }
    Timer { id: hideT; interval: 1400; onTriggered: osd.shown = false }
    Timer { id: killT; interval: 400; onTriggered: osd.up = false }

    Connections {
        target: Ui
        function onOsd() {
            if (!osd.ready) return;
            killT.stop();
            osd.up = true;
            osd.shown = true;
            hideT.restart();
        }
    }
    onShownChanged: if (!shown) killT.restart()

    // volume changes from any source (keys, mixer, popup)
    Connections {
        target: Audio
        function onVolumeChanged() { Ui.showOsd("vol", Audio.volume, Audio.muted); }
        function onMutedChanged() { Ui.showOsd("vol", Audio.volume, Audio.muted); }
    }

    LazyLoader {
        active: osd.up
        PanelWindow {
            screen: Quickshell.screens[0]
            anchors { bottom: true }
            margins { bottom: 70 }
            implicitWidth: 260
            implicitHeight: 60
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}
            WlrLayershell.namespace: "ddcoz-osd"
            WlrLayershell.layer: WlrLayer.Overlay

            Rectangle {
                id: card
                width: 240; height: 48
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 24
                color: Theme.panel
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)
                opacity: osd.shown ? 1 : 0
                y: osd.shown ? 6 : 16
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                readonly property bool vol: Ui.osdKind === "vol"
                readonly property real v: Ui.osdMuted ? 0 : Ui.osdValue
                Text {
                    id: ic
                    x: 16
                    width: 22; height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: !card.vol ? "" : card.v <= 0.001 ? "" : card.v < 0.4 ? "" : ""
                    color: Theme.fg
                    font.family: Theme.icons; font.pixelSize: 16
                }
                Rectangle {
                    anchors { left: ic.right; leftMargin: 14; right: pct.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    height: 8; radius: 4
                    color: Qt.rgba(1, 1, 1, 0.12)
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, card.v)); height: parent.height; radius: 4
                        color: Theme.accent
                        Behavior on width { NumberAnimation { duration: 90 } }
                    }
                }
                Text {
                    id: pct
                    anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                    width: 34
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(card.v * 100)
                    color: Theme.dim; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium
                }
            }
        }
    }
}
