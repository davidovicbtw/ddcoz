import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "singletons"

Panel {
    id: p
    name: "media"
    panelWidth: 360
    readonly property var player: Mpris.players.values.find(x => x.isPlaying) || Mpris.players.values[0] || null

    Timer {
        interval: 1000; repeat: true
        running: p.open && p.player && p.player.isPlaying
        onTriggered: p.player.positionChanged()
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 14
        Rectangle {
            Layout.preferredWidth: 84; Layout.preferredHeight: 84
            radius: 16; color: Theme.card; clip: true
            Image {
                anchors.fill: parent
                source: p.player ? p.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
            Text { anchors.centerIn: parent; text: ""; font.family: Theme.icons; font.pixelSize: 28; color: Theme.dim }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: p.player ? p.player.trackTitle : ""
                elide: Text.ElideRight
                color: Theme.fg; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.DemiBold
            }
            Text {
                Layout.fillWidth: true
                text: p.player ? p.player.trackArtist : ""
                elide: Text.ElideRight
                color: Theme.dim; font.family: Theme.font; font.pixelSize: 12
            }
            Text {
                Layout.fillWidth: true
                text: p.player ? p.player.identity : ""
                elide: Text.ElideRight
                color: Theme.dim; font.family: Theme.font; font.pixelSize: 11
            }
        }
    }
    Slid {
        Layout.fillWidth: true
        implicitHeight: 12
        visible: p.player && p.player.length > 0 && p.player.canSeek
        value: p.player && p.player.length > 0 ? p.player.position / p.player.length : 0
        onMoved: v => { p.player.position = v * p.player.length; }
    }
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 10
        IconBtn { icon: ""; size: 16; onClicked: p.player && p.player.previous() }
        Rectangle {
            width: 46; height: 46; radius: 23; color: Theme.accent
            scale: pm.pressed ? 0.92 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }
            Text {
                anchors.centerIn: parent
                text: p.player && p.player.isPlaying ? "" : ""
                font.family: Theme.icons; font.pixelSize: 18; color: Theme.accentText
            }
            MouseArea { id: pm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: p.player && p.player.togglePlaying() }
        }
        IconBtn { icon: ""; size: 16; onClicked: p.player && p.player.next() }
    }
}
