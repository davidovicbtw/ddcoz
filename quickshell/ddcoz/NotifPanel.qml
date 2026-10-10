import QtQuick
import QtQuick.Layouts
import "singletons"

// Notification history + quick actions.
Panel {
    id: p
    name: "notif"
    panelWidth: 360
    onOpened: Notifs.unread = 0

    RowLayout {
        Layout.fillWidth: true
        Text { text: "Notifications"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true }
        Text { text: "Do not disturb"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }
        Tog { on: Notifs.dnd; onToggled: Notifs.dnd = !Notifs.dnd }
    }

    // quick actions
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: [
                { t: "Shot", i: "", c: "$HOME/.local/bin/ddcoz-shot" },
                { t: "Clipboard", i: "" },
                { t: "Lock", i: "", c: "$HOME/.local/bin/ddcoz-lock" }
            ]
            delegate: Btn {
                required property var modelData
                Layout.fillWidth: true
                text: modelData.t
                icon: modelData.i
                onClicked: {
                    Ui.close();
                    if (modelData.t === "Clipboard") Qt.callLater(Ui.toggleClipboard);
                    else Sys.run(modelData.c);
                }
            }
        }
    }

    Item {
        visible: Notifs.history.count === 0
        Layout.fillWidth: true
        implicitHeight: 90
        Column {
            anchors.centerIn: parent
            spacing: 6
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: ""; color: Qt.rgba(1, 1, 1, 0.25); font.family: Theme.icons; font.pixelSize: 26 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No notifications"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 12 }
        }
    }

    ListView {
        id: lv
        visible: Notifs.history.count > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 320)
        clip: true
        spacing: 4
        boundsBehavior: Flickable.StopAtBounds
        model: Notifs.history
        delegate: Rectangle {
            id: d
            required property int index
            required property string app
            required property string summary
            required property string body
            required property string icon
            required property string stamp
            required property bool critical
            width: lv.width
            height: txt.implicitHeight + 20
            radius: 14
            color: ma.containsMouse ? Theme.cardHover : Theme.card
            border.width: critical ? 1 : 0
            border.color: Theme.danger
            Behavior on color { ColorAnimation { duration: 120 } }
            Rectangle {
                id: ico
                x: 10; y: 10
                width: 32; height: 32; radius: 10; color: Qt.rgba(1, 1, 1, 0.06); clip: true
                Image { anchors.fill: parent; source: d.icon; fillMode: Image.PreserveAspectFit; asynchronous: true; sourceSize: Qt.size(64, 64) }
            }
            Column {
                id: txt
                anchors { left: ico.right; leftMargin: 10; right: parent.right; rightMargin: 36; top: parent.top; topMargin: 10 }
                spacing: 1
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: d.summary
                    color: Theme.fg; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold
                }
                Text {
                    visible: d.body !== ""
                    width: parent.width
                    text: d.body
                    textFormat: Text.StyledText
                    wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                    color: Theme.dim; font.family: Theme.font; font.pixelSize: 11
                }
                Text { text: (d.app ? d.app + "  ·  " : "") + d.stamp; color: Qt.rgba(1, 1, 1, 0.35); font.family: Theme.font; font.pixelSize: 10 }
            }
            Text {
                anchors { right: parent.right; rightMargin: 12; top: parent.top; topMargin: 10 }
                text: ""; opacity: ma.containsMouse ? 1 : 0
                color: Theme.dim; font.family: Theme.icons; font.pixelSize: 11
            }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.remove(d.index) }
        }
    }
    Btn {
        visible: Notifs.history.count > 0
        text: "Clear all"
        icon: ""
        danger: true
        onClicked: Notifs.clear()
    }
}
