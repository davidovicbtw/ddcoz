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
    color: open ? "transparent" : Theme.bg
    border.width: 1
    border.color: open ? "transparent" : Theme.border
    Behavior on color { ColorAnimation { duration: pill.open ? 0 : Theme.durSlow } }
    Behavior on border.color { ColorAnimation { duration: pill.open ? 0 : Theme.durSlow } }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: pill.spacing
        height: parent.height
        enabled: !pill.open
        opacity: pill.open ? 0 : 1
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: pill.open ? 0 : Theme.durSlow * 0.55 }
                NumberAnimation { duration: pill.open ? 90 : Theme.dur }
            }
        }
    }
}
