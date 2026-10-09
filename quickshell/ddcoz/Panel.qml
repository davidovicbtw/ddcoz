import QtQuick
import QtQuick.Layouts
import "singletons"

// A popup that grows out of the bar bubble it belongs to (dynamic-island style).
Rectangle {
    id: p
    default property alias content: col.data
    required property string name
    required property string screenName
    property int panelWidth: 340
    readonly property bool open: Ui.popup === name && Ui.screenName === screenName
    readonly property real topPad: 16
    signal opened()

    // collapsed geometry = the bubble, captured on open
    property real ox: 0
    property real oy: 0
    property real ow: 0
    property real oh: 0
    property bool expanded: false
    property bool anim: false

    readonly property real fw: panelWidth
    readonly property real fh: topPad + col.implicitHeight + 14
    readonly property real fx: Math.max(8, Math.min(parent.width - fw - 8, ox + ow / 2 - fw / 2))

    x: expanded ? fx : ox
    y: oy
    width: expanded ? fw : ow
    height: expanded ? fh : oh
    radius: expanded ? 26 : oh / 2
    color: expanded ? Theme.panel : Theme.bg
    border.width: 1
    border.color: Theme.border
    clip: true
    opacity: (open || closing.running) ? 1 : 0
    visible: opacity > 0.01

    Behavior on x { enabled: p.anim; NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }
    Behavior on width { enabled: p.anim; NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }
    Behavior on height { enabled: p.anim; NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
    Behavior on radius { enabled: p.anim; NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutCubic } }
    Behavior on color { enabled: p.anim; ColorAnimation { duration: Theme.durSlow } }

    Timer { id: closing; interval: Theme.durSlow + 60 }

    onOpenChanged: {
        if (open) {
            anim = false;
            ox = Ui.origin.x; oy = Ui.origin.y; ow = Ui.origin.width; oh = Ui.origin.height;
            expanded = false;
            Qt.callLater(() => { p.anim = true; p.expanded = true; });
            opened();
        } else {
            expanded = false;
            closing.restart();
        }
    }

    MouseArea { anchors.fill: parent }
    ColumnLayout {
        id: col
        x: 14
        y: p.topPad
        width: p.fw - 28
        spacing: 8
        opacity: p.expanded ? 1 : 0
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: p.expanded ? Theme.dur * 0.35 : 0 }
                NumberAnimation { duration: p.expanded ? Theme.dur : 90 }
            }
        }
    }
}
