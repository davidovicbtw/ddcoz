import QtQuick
import "singletons"

// One floating bubble of the bar.
Rectangle {
    id: pill
    default property alias content: row.data
    property int pad: 6
    property int spacing: 2
    property bool open: false
    implicitWidth: row.implicitWidth + pad * 2
    implicitHeight: Theme.pillH
    height: Theme.pillH
    radius: height / 2
    color: Theme.bg
    border.width: 1
    border.color: Theme.border
    Row {
        id: row
        anchors.centerIn: parent
        spacing: pill.spacing
        height: parent.height - 2
    }
}
