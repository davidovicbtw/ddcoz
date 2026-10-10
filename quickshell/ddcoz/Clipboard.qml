import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "singletons"

// Clipboard history (cliphist). Window exists only while open.
Scope {
    LazyLoader {
        active: Ui.clipboard
        PanelWindow {
            id: win
            screen: Quickshell.screens[0]
            anchors { top: true; left: true; right: true; bottom: true }
            exclusionMode: ExclusionMode.Ignore
            color: Qt.rgba(0, 0, 0, 0.25)
            WlrLayershell.namespace: "ddcoz-clipboard"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            property var all: []
            readonly property string q: input.text.trim().toLowerCase()
            readonly property var items: q === "" ? all : all.filter(e => e.text.toLowerCase().indexOf(q) >= 0)

            function pick(e) {
                if (!e) return;
                Sys.run("cliphist decode " + e.id + " | wl-copy");
                Ui.clipboard = false;
            }
            function drop(e) {
                if (!e) return;
                Sys.run("printf '%s\\t\\n' " + e.id + " | cliphist delete");
                win.all = win.all.filter(x => x.id !== e.id);
            }

            Process {
                running: true
                command: ["cliphist", "list"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const out = [];
                        for (const line of text.split("\n")) {
                            const t = line.indexOf("\t");
                            if (t < 1) continue;
                            const id = parseInt(line.slice(0, t));
                            let body = line.slice(t + 1);
                            const img = /^\[\[ binary data (.*?) (png|jpg|jpeg|bmp|webp|gif) /.exec(body);
                            out.push({ id: id, text: img ? "Image  ·  " + img[1] + " " + img[2] : body.replace(/\s+/g, " ").trim(), image: !!img });
                            if (out.length >= 150) break;
                        }
                        win.all = out;
                    }
                }
            }

            MouseArea { anchors.fill: parent; onClicked: Ui.clipboard = false }

            Rectangle {
                id: card
                width: 560
                height: Math.min(parent.height - 120, 78 + Math.max(1, Math.min(win.items.length, 9)) * 48)
                anchors.centerIn: parent
                radius: 26
                color: Theme.panel
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)
                clip: true
                opacity: 0; scale: 0.96
                Component.onCompleted: { opacity = 1; scale = 1; input.forceActiveFocus(); }
                Behavior on opacity { NumberAnimation { duration: 140 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                MouseArea { anchors.fill: parent }

                Rectangle {
                    id: bar
                    x: 14; y: 14
                    width: parent.width - 28; height: 44
                    radius: 22
                    color: Theme.card
                    Text { x: 16; height: parent.height; verticalAlignment: Text.AlignVCenter; text: ""; color: Theme.dim; font.family: Theme.icons; font.pixelSize: 15 }
                    TextInput {
                        id: input
                        x: 44; width: parent.width - 60; height: parent.height
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.fg; font.family: Theme.font; font.pixelSize: 14
                        selectionColor: Theme.accent
                        clip: true
                        onTextChanged: list.currentIndex = 0
                        Keys.onEscapePressed: Ui.clipboard = false
                        Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
                        Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
                        Keys.onReturnPressed: win.pick(win.items[list.currentIndex])
                        Keys.onPressed: e => { if (e.key === Qt.Key_D && (e.modifiers & Qt.ControlModifier)) { win.drop(win.items[list.currentIndex]); e.accepted = true; } }
                        Text {
                            visible: input.text === ""
                            height: parent.height; verticalAlignment: Text.AlignVCenter
                            text: "Search clipboard   (Enter paste · Ctrl+D delete)"
                            color: Qt.rgba(1, 1, 1, 0.35); font: input.font
                        }
                    }
                }

                ListView {
                    id: list
                    anchors { left: parent.left; right: parent.right; top: bar.bottom; bottom: parent.bottom; margins: 14; topMargin: 8 }
                    clip: true
                    spacing: 2
                    model: win.items
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 80
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: list.width; height: 46; radius: 14
                        color: ListView.isCurrentItem ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                        Text {
                            x: 14; width: 20; height: parent.height
                            verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                            text: modelData.image ? "" : ""
                            color: modelData.image ? Theme.accent : Theme.dim; font.family: Theme.icons; font.pixelSize: 14
                        }
                        Text {
                            x: 46; width: parent.width - 62; height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            text: modelData.text; elide: Text.ElideRight; maximumLineCount: 1
                            color: Theme.fg; font.family: Theme.font; font.pixelSize: 13
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onEntered: list.currentIndex = index
                            onClicked: win.pick(modelData)
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: list.count === 0
                        text: win.all.length === 0 ? "Clipboard is empty" : "No matches"
                        color: Theme.dim; font.family: Theme.font; font.pixelSize: 13
                    }
                }
            }
        }
    }
}
