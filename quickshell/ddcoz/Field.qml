import QtQuick
import "singletons"

Rectangle {
    id: f
    property alias text: input.text
    property string placeholder: ""
    property bool password: false
    signal accepted()
    signal goUp()
    signal goDown()
    signal cancel()
    function focusInput() { input.forceActiveFocus(); }
    implicitHeight: 34
    radius: 12
    color: Qt.rgba(1, 1, 1, 0.08)
    border.width: input.activeFocus ? 1 : 0
    border.color: Theme.accent
    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        verticalAlignment: Text.AlignVCenter
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: 13
        echoMode: f.password ? TextInput.Password : TextInput.Normal
        selectByMouse: true
        clip: true
        onAccepted: f.accepted()
        Keys.onUpPressed: f.goUp()
        Keys.onDownPressed: f.goDown()
        Keys.onEscapePressed: f.cancel()
        Text {
            visible: !input.text && !input.activeFocus
            anchors.verticalCenter: parent.verticalCenter
            text: f.placeholder
            color: Theme.dim
            font: input.font
        }
    }
}
