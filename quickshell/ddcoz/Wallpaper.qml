import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "singletons"

// Full-screen wallpaper carousel: big cards, centre one enlarged, arrows to browse, Enter to apply.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "ddcoz-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.wallpaper ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property var all: []
    property string query: ""
    readonly property var files: filter(all, query)
    readonly property var colors: ["red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink", "brown", "black", "gray", "white"]
    readonly property var swatch: ({ red: "#e5484d", orange: "#f5871f", yellow: "#f2c94c", green: "#3fb950", cyan: "#2ec5d3", blue: "#3b82f6", purple: "#9b5de5", pink: "#f472b6", brown: "#8b5e3c", black: "#111111", gray: "#888b94", white: "#f4f4f5" })
    readonly property var alias: ({ "kırmızı": "red", "kirmizi": "red", "turuncu": "orange", "sarı": "yellow", "sari": "yellow", "yeşil": "green", "yesil": "green", "turkuaz": "cyan", "mavi": "blue", "mor": "purple", "pembe": "pink", "kahverengi": "brown", "kahve": "brown", "siyah": "black", "gri": "gray", "beyaz": "white", "koyu": "dark", "açık": "light", "acik": "light" })

    function filter(list, q) {
        const words = q.toLowerCase().split(/\s+/).filter(w => w !== "").map(w => alias[w] || w);
        if (words.length === 0) return list.map(e => e.path);
        return list.filter(e => {
            const name = nameOf(e.path).toLowerCase();
            return words.every(w => name.indexOf(w) >= 0 || e.tags.some(t => t.indexOf(w) === 0));
        }).map(e => e.path);
    }
    property string current: ""
    property bool linger: false
    property bool shown: false
    visible: Ui.wallpaper || linger

    function nameOf(p) { return p ? p.split("/").pop().replace(/\.[^.]+$/, "") : ""; }
    function apply(p) {
        current = p;
        Quickshell.execDetached(["sh", "-c",
            'awww img "$1" --transition-type grow --transition-duration 0.8 --transition-fps 60 && mkdir -p ~/.config/ddcoz && printf %s "$1" > ~/.config/ddcoz/wallpaper',
            "sh", p]);
    }

    Process {
        id: lister
        command: [Quickshell.env("HOME") + "/.local/bin/ddcoz-wallcolors", win.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                win.all = text.split("\n").filter(l => l !== "").map(l => {
                    const i = l.indexOf("\t");
                    return { path: l.slice(0, i), tags: l.slice(i + 1).split(" ").filter(t => t !== "") };
                });
                win.focusCurrent();
            }
        }
    }
    Process {
        id: querier
        command: ["sh", "-c", "awww query | sed -n 's/.*image: //p' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: { win.current = text.trim(); win.focusCurrent(); }
        }
    }
    function focusCurrent() {
        const i = files.indexOf(current);
        strip.highlightMoveDuration = 0;
        strip.currentIndex = i >= 0 ? i : 0;
        settle.restart();
    }

    Timer { id: settle; interval: 60; onTriggered: strip.highlightMoveDuration = 320 }

    onFilesChanged: if (visible) focusCurrent()

    Connections {
        target: Ui
        function onWallpaperChanged() {
            if (Ui.wallpaper) {
                win.linger = true;
                search.text = Ui.wallQuery; win.query = Ui.wallQuery;
                lister.running = false; lister.running = true;
                querier.running = false; querier.running = true;
                Qt.callLater(() => { win.shown = true; search.forceActiveFocus(); });
            } else {
                win.shown = false;
                hide.restart();
            }
        }
    }
    Timer { id: hide; interval: Theme.durSlow + 60; onTriggered: win.linger = false }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.03, 0.035, 0.05, 0.78)
        opacity: win.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; onClicked: Ui.wallpaper = false }
    }

    Item {
        anchors.fill: parent
        opacity: win.shown ? 1 : 0
        transform: Translate { y: win.shown ? 0 : 30; Behavior on y { NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutCubic } } }
        Behavior on opacity { NumberAnimation { duration: Theme.dur } }

        Text {
            id: heading
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.07 }
            text: "Wallpaper"
            color: Theme.fg
            font.family: Theme.font; font.pixelSize: 30; font.weight: Font.DemiBold
        }

        Rectangle {
            id: searchBox
            anchors { horizontalCenter: parent.horizontalCenter; top: heading.bottom; topMargin: 18 }
            width: 420; height: 44; radius: 22
            color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: search.activeFocus ? Theme.accent : Theme.border
            Behavior on border.color { ColorAnimation { duration: 160 } }
            Text {
                id: mag
                anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                text: "\uf002"; color: Theme.dim
                font.family: Theme.icons; font.pixelSize: 14
            }
            TextInput {
                id: search
                anchors { left: mag.right; leftMargin: 12; right: clear.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                color: Theme.fg
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentText
                font.family: Theme.font; font.pixelSize: 16
                clip: true
                onTextChanged: win.query = text
                Keys.onLeftPressed: strip.step(-1)
                Keys.onRightPressed: strip.step(1)
                Keys.onUpPressed: strip.step(-5)
                Keys.onDownPressed: strip.step(5)
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Home) { strip.currentIndex = 0; e.accepted = true; }
                    else if (e.key === Qt.Key_End) { strip.currentIndex = strip.count - 1; e.accepted = true; }
                    else if (e.key === Qt.Key_PageUp) { strip.step(-10); e.accepted = true; }
                    else if (e.key === Qt.Key_PageDown) { strip.step(10); e.accepted = true; }
                    else if (e.key === Qt.Key_R && (e.modifiers & Qt.ControlModifier) && strip.count > 0) { strip.currentIndex = Math.floor(Math.random() * strip.count); e.accepted = true; }
                }
                Keys.onEscapePressed: { if (text !== "") text = ""; else Ui.wallpaper = false; }
                Keys.onReturnPressed: if (strip.currentIndex >= 0 && strip.count > 0) win.apply(win.files[strip.currentIndex])
                Keys.onEnterPressed: if (strip.currentIndex >= 0 && strip.count > 0) win.apply(win.files[strip.currentIndex])
                Text {
                    visible: search.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search name or colour…  (red, mavi, dark)"
                    color: Theme.dim; font: search.font
                }
            }
            Text {
                id: clear
                visible: search.text !== ""
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                text: "\uf00d"; color: Theme.dim
                font.family: Theme.icons; font.pixelSize: 13
                MouseArea { anchors { fill: parent; margins: -8 } cursorShape: Qt.PointingHandCursor; onClicked: { search.text = ""; search.forceActiveFocus(); } }
            }
        }

        Row {
            id: chips
            anchors { horizontalCenter: parent.horizontalCenter; top: searchBox.bottom; topMargin: 16 }
            spacing: 12
            Repeater {
                model: win.colors
                delegate: Rectangle {
                    id: chip
                    required property string modelData
                    readonly property bool on: win.query.trim().toLowerCase() === modelData
                    width: 26; height: 26; radius: 13
                    color: win.swatch[modelData]
                    border.width: on ? 3 : 1
                    border.color: on ? Theme.fg : Qt.rgba(1, 1, 1, 0.25)
                    scale: on ? 1.2 : chipMa.containsMouse ? 1.1 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                    MouseArea {
                        id: chipMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { search.text = chip.on ? "" : chip.modelData; search.forceActiveFocus(); }
                    }
                }
            }
        }

        ListView {
            id: strip
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            height: 380
            orientation: ListView.Horizontal
            spacing: 26
            model: win.visible ? win.files : []
            clip: false
            cacheBuffer: 1200
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - 260
            preferredHighlightEnd: width / 2 - 260
            highlightMoveDuration: 320
            highlightMoveVelocity: -1
            snapMode: ListView.NoSnap
            keyNavigationEnabled: false
            function step(n) { currentIndex = Math.max(0, Math.min(count - 1, currentIndex + n)); }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: w => strip.step(w.angleDelta.y + w.angleDelta.x > 0 ? -1 : 1)
            }

            delegate: Item {
                id: card
                required property string modelData
                required property int index
                readonly property bool cur: ListView.isCurrentItem
                readonly property bool applied: win.current === modelData
                width: cur ? 520 : 340
                height: strip.height
                Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

                Rectangle {
                    id: frame
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: card.cur ? 330 : 220
                    radius: 28
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: card.cur ? 3 : 1
                    border.color: card.cur ? Theme.accent : Theme.border
                    opacity: card.cur ? 1 : 0.65
                    clip: true
                    Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    Image {
                        anchors { fill: parent; margins: card.cur ? 3 : 1 }
                        source: "file://" + card.modelData
                        sourceSize: Qt.size(640, 400)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        smooth: true
                    }
                    Rectangle {
                        visible: card.applied
                        anchors { top: parent.top; right: parent.right; margins: 12 }
                        height: 26; width: tag.implicitWidth + 20; radius: 13
                        color: Theme.accent
                        Text {
                            id: tag
                            anchors.centerIn: parent
                            text: "  Current"
                            color: Theme.accentText
                            font.family: Theme.icons; font.pixelSize: 11; font.weight: Font.Bold
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (card.cur) win.apply(card.modelData);
                            else strip.currentIndex = card.index;
                        }
                    }
                }
            }
        }

        Column {
            anchors { horizontalCenter: parent.horizontalCenter; top: strip.bottom; topMargin: 8 }
            spacing: 8
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: strip.count > 0 ? win.nameOf(win.files[strip.currentIndex]) : (win.all.length > 0 ? "No wallpaper matches \"" + win.query + "\"" : "Loading…")
                color: Theme.fg
                font.family: Theme.font; font.pixelSize: 20; font.weight: Font.Medium
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: strip.count > 0 ? (strip.currentIndex + 1) + " / " + strip.count + (win.query !== "" ? "  ·  of " + win.all.length : "") : ""
                color: Theme.dim
                font.family: Theme.font; font.pixelSize: 13
            }
        }
        Text {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: parent.height * 0.08 }
            text: "type to search      ←  →  browse      ↑  ↓  jump 5      Ctrl+R  random      Enter  apply      Esc  clear / close"
            color: Theme.dim
            font.family: Theme.font; font.pixelSize: 13
        }
    }
}
