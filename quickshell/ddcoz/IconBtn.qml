import QtQuick
import "singletons"

Item {
    id: b
    property string icon: ""
    property string label: ""
    property string sub: ""
    property color color: Theme.fg
    property real size: 12
    property bool active: false
    property bool flat: false
    readonly property color tint: active ? Theme.accent : color
    signal clicked()
    signal rightClicked()
    signal wheel(int dy)

    implicitWidth: Math.max(Theme.pillH - 2, contentRow.implicitWidth + 18)
    implicitHeight: Theme.pillH - 2
    y: 0
    height: implicitHeight
    scale: ma.pressed ? 0.92 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 0
        radius: height / 2
        color: b.active ? Qt.alpha(Theme.accent, 0.20) : ma.containsMouse && !b.flat ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
        Behavior on color { ColorAnimation { duration: 140 } }
    }
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6
        Text {
            visible: b.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            height: b.height
            verticalAlignment: Text.AlignVCenter
            text: b.icon
            color: b.tint
            Behavior on color { ColorAnimation { duration: 140 } }
            font.family: Theme.icons
            font.pixelSize: b.size
        }
        Text {
            visible: b.label !== ""
            anchors.verticalCenter: parent.verticalCenter
            height: b.height
            verticalAlignment: Text.AlignVCenter
            text: b.label
            color: b.tint
            Behavior on color { ColorAnimation { duration: 140 } }
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
        Text {
            visible: b.sub !== ""
            anchors.verticalCenter: parent.verticalCenter
            height: b.height
            verticalAlignment: Text.AlignVCenter
            text: b.sub
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton ? b.rightClicked() : b.clicked()
        onWheel: w => b.wheel(w.angleDelta.y)
    }
}
