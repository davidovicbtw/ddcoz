import QtQuick
import QtQuick.Layouts
import "singletons"

Panel {
    id: p
    name: "bat"
    readonly property var names: ({ "power-saver": "Saver", "balanced": "Balanced", "performance": "Performance" })

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: Sys.hasBattery ? Math.round(Sys.percent) + "%" : "AC"
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 30
            font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }
        Column {
            Layout.alignment: Qt.AlignVCenter
            Text {
                anchors.right: parent.right
                text: !Sys.hasBattery ? "No battery" : Sys.charging ? (Sys.percent >= 99 ? "Fully charged" : "Charging") : "On battery"
                color: Theme.fg; font.family: Theme.font; font.pixelSize: 13
            }
            Text {
                anchors.right: parent.right
                visible: Sys.eta() !== ""
                text: Sys.eta() + (Sys.charging ? " until full" : " remaining")
                color: Theme.dim; font.family: Theme.font; font.pixelSize: 11
            }
        }
    }
    Rectangle {
        visible: Sys.hasBattery
        Layout.fillWidth: true
        height: 8; radius: 4
        color: Qt.rgba(1, 1, 1, 0.10)
        Rectangle {
            width: parent.width * Math.min(1, Sys.percent / 100)
            height: parent.height; radius: 4
            color: Sys.charging ? "#5fd38d" : Sys.percent < 20 ? Theme.danger : Theme.accent
            Behavior on width { NumberAnimation { duration: Theme.dur } }
        }
    }
    Text { text: "Power mode"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 12; Layout.topMargin: 6 }
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: Sys.profiles
            delegate: Btn {
                required property string modelData
                Layout.fillWidth: true
                text: p.names[modelData]
                filled: Sys.profile === modelData
                onClicked: Sys.setProfile(modelData)
            }
        }
    }
}
