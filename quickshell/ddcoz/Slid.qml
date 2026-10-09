import QtQuick
import "singletons"

Item {
    id: s
    property real value: 0
    property string icon: ""
    signal moved(real v)
    signal iconClicked()
    implicitHeight: 34
    implicitWidth: 200

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.10)
        clip: true
        Rectangle {
            width: Math.max(parent.height, parent.width * s.value)
            height: parent.height
            radius: height / 2
            color: Theme.accent
            Behavior on width { enabled: !ma.pressed; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
    }
    Text {
        visible: s.icon !== ""
        x: 11
        anchors.verticalCenter: parent.verticalCenter
        text: s.icon
        font.family: Theme.icons
        font.pixelSize: 15
        color: s.value > 0.12 ? Theme.accentText : Theme.fg
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function upd(x) { s.moved(Math.max(0, Math.min(1, x / width))); }
        onPressed: m => m.x < 30 && s.icon !== "" ? s.iconClicked() : upd(m.x)
        onPositionChanged: m => { if (pressed && m.x >= 0) upd(m.x); }
        onWheel: w => s.moved(Math.max(0, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.04 : -0.04))))
    }
}
