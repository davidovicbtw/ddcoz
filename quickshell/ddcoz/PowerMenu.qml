import QtQuick
import Quickshell
import Quickshell.Wayland
import "singletons"

// Full-screen session menu: big icons, pick with the arrow keys + Enter (or the mouse).
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "ddcoz-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.powermenu ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool linger: false
    property bool shown: false
    property int sel: 0
    visible: Ui.powermenu || linger

    readonly property var items: [
        { title: "Lock", icon: "", cmd: "$HOME/.local/bin/ddcoz-lock" },
        { title: "Sleep", icon: "", cmd: "systemctl suspend" },
        { title: "Log out", icon: "", cmd: "hyprctl dispatch 'hl.dsp.exit()' || hyprctl dispatch exit" },
        { title: "Restart", icon: "", cmd: "systemctl reboot" },
        { title: "Shut down", icon: "", cmd: "systemctl poweroff", danger: true }
    ]

    Connections {
        target: Ui
        function onPowermenuChanged() {
            if (Ui.powermenu) {
                win.linger = true;
                win.sel = 0;
                Qt.callLater(() => { win.shown = true; keys.forceActiveFocus(); });
            } else {
                win.shown = false;
                hide.restart();
            }
        }
    }
    Timer { id: hide; interval: Theme.durSlow + 60; onTriggered: win.linger = false }

    function activate(i) {
        const it = items[i];
        Ui.powermenu = false;
        Sys.run(it.cmd);
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.03, 0.035, 0.05, 0.72)
        opacity: win.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; onClicked: Ui.powermenu = false }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Ui.powermenu = false
        Keys.onLeftPressed: win.sel = (win.sel + win.items.length - 1) % win.items.length
        Keys.onRightPressed: win.sel = (win.sel + 1) % win.items.length
        Keys.onTabPressed: win.sel = (win.sel + 1) % win.items.length
        Keys.onBacktabPressed: win.sel = (win.sel + win.items.length - 1) % win.items.length
        Keys.onReturnPressed: win.activate(win.sel)
        Keys.onEnterPressed: win.activate(win.sel)
        Keys.onPressed: e => {
            if (e.key === Qt.Key_H) win.sel = (win.sel + win.items.length - 1) % win.items.length;
            else if (e.key === Qt.Key_L) win.sel = (win.sel + 1) % win.items.length;
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_5) win.activate(e.key - Qt.Key_1);
        }

        Column {
            anchors.centerIn: parent
            spacing: 44
            opacity: win.shown ? 1 : 0
            scale: win.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: Theme.dur } }
            Behavior on scale { NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }

            Row {
                id: row
                spacing: 22
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: win.items
                    delegate: Rectangle {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool cur: win.sel === index
                        width: 168; height: 168
                        radius: 40
                        scale: cur ? 1.1 : 1
                        color: cur ? (modelData.danger ? Theme.danger : Theme.accent) : Qt.rgba(1, 1, 1, 0.07)
                        border.width: 1
                        border.color: cur ? "transparent" : Theme.border
                        Behavior on scale { NumberAnimation { duration: Theme.dur; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Text {
                            anchors.centerIn: parent
                            text: tile.modelData.icon
                            color: tile.cur ? Theme.accentText : tile.modelData.danger ? Theme.danger : Theme.fg
                            font.family: Theme.icons
                            font.pixelSize: 64
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        Text {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 14 }
                            text: String(tile.index + 1)
                            color: tile.cur ? Qt.rgba(0, 0, 0, 0.4) : Theme.dim
                            font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Medium
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.sel = tile.index
                            onClicked: win.activate(tile.index)
                        }
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: win.items[win.sel].title
                color: Theme.fg
                font.family: Theme.font; font.pixelSize: 30; font.weight: Font.DemiBold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "←  →  select      Enter  confirm      Esc  cancel"
                color: Theme.dim
                font.family: Theme.font; font.pixelSize: 13
            }
        }
    }
}
