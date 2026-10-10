import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "singletons"

PanelWindow {
    id: win
    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { top: Theme.barH + 2; right: Theme.gap }
    implicitWidth: 380
    implicitHeight: 700
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "ddcoz-toasts"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region { item: list.count > 0 && Ui.popup === "" ? list : null }
    visible: Config.notifications

    ListView {
        id: list
        opacity: Ui.popup === "" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        width: 364
        height: contentHeight
        spacing: 8
        interactive: false
        model: Notifs.server.trackedNotifications
        verticalLayoutDirection: ListView.TopToBottom
        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dur }
                NumberAnimation { property: "x"; from: 60; to: 0; duration: Theme.durSlow; easing.type: Easing.OutBack; easing.overshoot: 1.0 }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: Theme.dur }
                NumberAnimation { property: "x"; to: 80; duration: Theme.dur; easing.type: Easing.InCubic }
            }
        }
        displaced: Transition { NumberAnimation { property: "y"; duration: Theme.dur; easing.type: Easing.OutCubic } }

        delegate: Rectangle {
            id: toast
            required property var modelData
            width: list.width
            height: body.implicitHeight + 28
            radius: 22
            color: Theme.panel
            border.width: 1
            border.color: modelData.urgency === NotificationUrgency.Critical ? Theme.danger : Theme.border

            Timer {
                interval: toast.modelData.expireTimeout > 0 ? toast.modelData.expireTimeout * 1000 : 6000
                running: toast.modelData.urgency !== NotificationUrgency.Critical && !ma.containsMouse
                onTriggered: toast.modelData.expire()
            }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: toast.modelData.dismiss() }

            Row {
                id: body
                x: 14; y: 14
                width: parent.width - 28
                spacing: 12
                Rectangle {
                    width: 40; height: 40; radius: 12; color: Theme.card; clip: true
                    Image {
                        anchors.fill: parent
                        source: toast.modelData.image || (toast.modelData.appIcon ? Quickshell.iconPath(toast.modelData.appIcon, true) : "")
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                }
                Column {
                    width: parent.width - 52
                    spacing: 2
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: toast.modelData.summary
                        color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold
                    }
                    Text {
                        visible: text !== ""
                        width: parent.width
                        text: toast.modelData.body
                        textFormat: Text.StyledText
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        color: Theme.dim; font.family: Theme.font; font.pixelSize: 12
                    }
                    Row {
                        visible: toast.modelData.actions.length > 0
                        spacing: 6
                        topPadding: 6
                        Repeater {
                            model: toast.modelData.actions
                            delegate: Btn {
                                required property var modelData
                                text: modelData.text
                                implicitHeight: 26
                                onClicked: modelData.invoke()
                            }
                        }
                    }
                }
            }
        }
    }
}
