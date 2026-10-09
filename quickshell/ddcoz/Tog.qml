import QtQuick
import "singletons"

Rectangle {
    id: t
    property bool on: false
    signal toggled()
    implicitWidth: 40
    implicitHeight: 22
    radius: 11
    color: on ? Theme.accent : Qt.rgba(1, 1, 1, 0.16)
    Behavior on color { ColorAnimation { duration: 160 } }
    Rectangle {
        width: 18; height: 18; radius: 9
        y: 2
        x: t.on ? parent.width - width - 2 : 2
        color: t.on ? Theme.accentText : "white"
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: t.toggled() }
}
