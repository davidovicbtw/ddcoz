import QtQuick
import "singletons"

Rectangle {
    id: b
    property string text: ""
    property string icon: ""
    property bool filled: false
    property bool danger: false
    signal clicked()
    implicitHeight: 32
    implicitWidth: lbl.implicitWidth + 28
    radius: 16
    color: filled ? (ma.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent)
                  : danger ? (ma.containsMouse ? Qt.rgba(1, 0.42, 0.42, 0.3) : Qt.rgba(1, 0.42, 0.42, 0.18))
                  : (ma.containsMouse ? Theme.cardHover : Theme.card)
    Behavior on color { ColorAnimation { duration: 120 } }
    scale: ma.pressed ? 0.95 : 1
    Behavior on scale { NumberAnimation { duration: 100 } }
    Text {
        id: lbl
        anchors.centerIn: parent
        text: (b.icon ? b.icon + "  " : "") + b.text
        textFormat: Text.PlainText
        color: b.filled ? Theme.accentText : b.danger ? Theme.danger : Theme.fg
        font.family: Theme.font
        font.pixelSize: 12
        font.weight: Font.Medium
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
}
