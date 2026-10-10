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
    // glass look: faint light on top fading into the base colour, accent ring while its popup is open
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.tint(Theme.bg, Qt.rgba(1, 1, 1, 0.08)) }
        GradientStop { position: 1; color: Theme.bg }
    }
    border.width: 1
    border.color: open ? Qt.alpha(Theme.accent, 0.55) : Qt.rgba(1, 1, 1, 0.10)
    Behavior on border.color { ColorAnimation { duration: 160 } }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: pill.spacing
        height: parent.height - 2
    }
}
