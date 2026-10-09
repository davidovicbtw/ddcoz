import QtQuick
import "singletons"

// Generic list row: icon, title, subtitle, trailing text/glyph.
Rectangle {
    id: r
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string trailing: ""
    property bool highlighted: false
    property color iconColor: Theme.fg
    signal clicked()
    implicitHeight: 44
    radius: 14
    color: highlighted ? Qt.rgba(1, 1, 1, 0.12) : ma.containsMouse ? Theme.card : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }
    Text {
        id: ic
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        text: r.icon
        color: r.iconColor
        font.family: Theme.icons
        font.pixelSize: 16
        width: 20
        horizontalAlignment: Text.AlignHCenter
    }
    Column {
        anchors { left: ic.right; leftMargin: 12; right: tr.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        Text {
            width: parent.width
            text: r.title
            elide: Text.ElideRight
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        Text {
            visible: r.subtitle !== ""
            width: parent.width
            text: r.subtitle
            elide: Text.ElideRight
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 11
        }
    }
    Text {
        id: tr
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        text: r.trailing
        color: Theme.dim
        font.family: Theme.icons
        font.pixelSize: 13
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: r.clicked() }
}
