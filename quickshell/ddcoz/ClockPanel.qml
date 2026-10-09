import QtQuick
import QtQuick.Layouts
import Quickshell
import "singletons"

Panel {
    id: p
    name: "clock"
    panelWidth: 320
    property int offset: 0
    onOpened: offset = 0
    SystemClock { id: clk; precision: SystemClock.Minutes }
    readonly property date shown: new Date(clk.date.getFullYear(), clk.date.getMonth() + offset, 1)

    Text {
        text: Qt.formatDateTime(clk.date, Config.clock24 ? "HH:mm" : "h:mm AP")
        color: Theme.fg; font.family: Theme.font; font.pixelSize: 34; font.weight: Font.DemiBold
    }
    Text {
        text: Qt.formatDateTime(clk.date, "dddd, d MMMM yyyy")
        color: Theme.dim; font.family: Theme.font; font.pixelSize: 13
        Layout.bottomMargin: 6
    }
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: Qt.formatDateTime(p.shown, "MMMM yyyy")
            color: Theme.fg; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.DemiBold
            Layout.fillWidth: true
        }
        IconBtn { icon: ""; size: 12; onClicked: p.offset-- }
        IconBtn { icon: ""; size: 8; onClicked: p.offset = 0 }
        IconBtn { icon: ""; size: 12; onClicked: p.offset++ }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 2
        columnSpacing: 0
        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            delegate: Text {
                required property string modelData
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11
            }
        }
        Repeater {
            model: 42
            delegate: Item {
                required property int index
                readonly property int lead: (p.shown.getDay() + 6) % 7
                readonly property date day: new Date(p.shown.getFullYear(), p.shown.getMonth(), index - lead + 1)
                readonly property bool inMonth: day.getMonth() === p.shown.getMonth()
                readonly property bool today: day.toDateString() === clk.date.toDateString()
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Rectangle {
                    anchors.centerIn: parent
                    width: 30; height: 30; radius: 15
                    color: today ? Theme.accent : "transparent"
                }
                Text {
                    anchors.centerIn: parent
                    text: day.getDate()
                    color: today ? Theme.accentText : inMonth ? Theme.fg : Qt.rgba(1, 1, 1, 0.25)
                    font.family: Theme.font; font.pixelSize: 13
                    font.weight: today ? Font.Bold : Font.Normal
                }
            }
        }
    }
}
