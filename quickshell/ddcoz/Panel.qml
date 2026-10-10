import QtQuick
import QtQuick.Layouts
import "singletons"

// A floating card that drops down under the bar button it belongs to.
Item {
    id: p
    default property alias content: col.data
    required property string name
    required property string screenName
    property int panelWidth: 340
    readonly property bool open: Ui.popup === name && Ui.screenName === screenName
    readonly property real topPad: 16
    signal opened()

    property real ox: 0
    property real ow: 0
    property bool shown: false

    readonly property real fw: panelWidth
    readonly property real fh: topPad + col.implicitHeight + 16

    x: Math.max(8, Math.min(parent.width - fw - 8, ox + ow / 2 - fw / 2))
    y: Theme.barH + 2
    width: fw
    height: fh
    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.94
    transformOrigin: Item.Top
    Behavior on opacity { NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: Theme.dur + 60; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
    transform: Translate { y: p.shown ? 0 : -8; Behavior on y { NumberAnimation { duration: Theme.dur + 60; easing.type: Easing.OutCubic } } }

    onOpenChanged: {
        shown = open;
        if (open) { ox = Ui.origin.x; ow = Ui.origin.width; opened(); }
    }

    // soft shadow layers
    Repeater {
        model: 4
        delegate: Rectangle {
            required property int index
            anchors.fill: card
            anchors.margins: -(index + 1) * 3
            radius: card.radius + (index + 1) * 3
            color: "black"
            opacity: 0.07
            z: -1
        }
    }
    Rectangle {
        id: card
        anchors.fill: parent
        radius: 22
        color: Theme.panel
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
        // top highlight
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 1 }
            height: parent.height / 2
            radius: parent.radius - 1
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.05) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    MouseArea { anchors.fill: parent }
    ColumnLayout {
        id: col
        x: 16
        y: p.topPad
        width: p.fw - 32
        spacing: 10
    }
}
