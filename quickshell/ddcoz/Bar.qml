import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "singletons"

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    mask: Region { x: 0; y: 0; width: win.width; height: win.hasPopup ? win.height : Theme.barH }
    WlrLayershell.keyboardFocus: win.hasPopup ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"
    WlrLayershell.namespace: "ddcoz-bar"

    readonly property string sname: modelData.name
    readonly property bool hasPopup: Ui.popup !== "" && Ui.screenName === sname
    function isOpen(n) { return Ui.popup === n && Ui.screenName === sname; }
    readonly property var player: Mpris.players.values.find(x => x.isPlaying) || Mpris.players.values[0] || null
    Binding { target: Ui; property: "logoRect"; value: Qt.rect(Theme.gap, (Theme.barH - Theme.pillH) / 2, Theme.pillH, Theme.pillH) }
    SystemClock { id: clock; precision: Config.seconds ? SystemClock.Seconds : SystemClock.Minutes }

    function pillFor(n) { return n === "clock" ? clockPill : n === "media" ? mediaPill : n === "power" ? powerPill : n === "notif" ? notifPill : statusPill; }
    Connections {
        target: Ui
        function onRequest(name) { if (win.modelData === Quickshell.screens[0]) win.pop(name, win.pillFor(name)); }
    }
    function pop(name, pill) { const q = pill.mapToItem(null, 0, 0); Ui.toggle(name, Qt.rect(q.x, q.y, pill.width, pill.height), sname); }
    function volIcon() { return Audio.muted || Audio.volume <= 0.001 ? "" : Audio.volume < 0.4 ? "" : ""; }
    function batIcon() {
        const p = Sys.percent;
        return Sys.charging ? "" : p > 85 ? "" : p > 60 ? "" : p > 35 ? "" : p > 12 ? "" : "";
    }

    // slide-in on start
    Item {
        id: root
        anchors.fill: parent
        opacity: 0
        transform: Translate { id: slide; y: -20; Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } }
        Component.onCompleted: { opacity = 1; slide.y = 0; }
        Behavior on opacity { NumberAnimation { duration: 500 } }

        focus: true
        Keys.onEscapePressed: Ui.close()
        MouseArea { anchors.fill: parent; enabled: win.hasPopup; onPressed: Ui.close() }
        WifiPanel { screenName: win.sname }
        BtPanel { screenName: win.sname }
        VolPanel { screenName: win.sname }
        BatPanel { screenName: win.sname }
        ClockPanel { screenName: win.sname }
        MediaPanel { screenName: win.sname }
        NotifPanel { screenName: win.sname }

        // ---- left ----
        Row {
            anchors { left: parent.left; leftMargin: Theme.gap; top: parent.top; topMargin: (Theme.barH - Theme.pillH) / 2 }
            spacing: Theme.gap
            Pill {
                id: logoPill
                width: Theme.pillH
                open: Ui.launcher
                IconBtn { icon: ""; size: 14; active: Ui.launcher; onClicked: Ui.toggleLauncher() }
            }
            Pill {
                pad: 8
                spacing: 6
                Repeater {
                    model: Config.workspaces
                    delegate: Item {
                        id: wsd
                        required property int index
                        readonly property int wid: index + 1
                        readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wid)
                        readonly property bool focused: !!Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wid
                        anchors.verticalCenter: parent.verticalCenter
                        width: focused ? 20 : 10
                        height: parent.height
                        Behavior on width { NumberAnimation { duration: Theme.dur; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width; height: wsd.focused ? 8 : 6; radius: height / 2
                            color: wsd.focused ? Theme.accent : wsd.ws ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(1, 1, 1, 0.25)
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        MouseArea {
                            anchors { fill: parent; margins: -2 }
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + wsd.wid + "\" })")
                        }
                    }
                }
            }
            Pill {
                readonly property string t: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                visible: t !== ""
                pad: 12
                Text {
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    width: Math.min(implicitWidth, 300)
                    text: parent.parent.t
                    elide: Text.ElideRight
                    color: Theme.dim; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium
                }
            }
        }

        // ---- center ----
        Pill {
            id: clockPill
            open: win.isOpen("clock")
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: (Theme.barH - Theme.pillH) / 2
            Item {
                id: recBtn
                visible: Sys.recording
                width: visible ? recLbl.implicitWidth + 24 : 0
                height: Theme.pillH
                Row {
                    anchors.centerIn: parent
                    spacing: 7
                    Rectangle {
                        width: 9; height: 9; radius: 5; anchors.verticalCenter: parent.verticalCenter
                        color: Theme.danger
                        visible: !recMa.containsMouse
                        SequentialAnimation on opacity {
                            running: Sys.recording; loops: Animation.Infinite
                            NumberAnimation { to: 0.25; duration: 700 }
                            NumberAnimation { to: 1; duration: 700 }
                        }
                    }
                    Text {
                        id: recLbl
                        anchors.verticalCenter: parent.verticalCenter
                        text: recMa.containsMouse ? "\u25A0  Stop & Save" : "REC  " + Sys.recTime
                        color: recMa.containsMouse ? Theme.danger : Theme.fg
                        font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold
                    }
                }
                MouseArea { id: recMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Sys.stopRec() }
            }
            IconBtn {
                id: clockBtn
                visible: !Sys.recording
                active: Ui.popup === "clock" && Ui.screenName === win.sname
                label: (Config.seconds ? Qt.formatDateTime(clock.date, Config.clock24 ? "HH:mm:ss" : "h:mm:ss AP") : Qt.formatDateTime(clock.date, Config.clock24 ? "HH:mm" : "h:mm AP"))
                       + "  ·  " + Qt.formatDateTime(clock.date, "ddd d MMM")
                onClicked: win.pop("clock", clockPill)
            }
        }
        Pill {
            id: mediaPill
            open: win.isOpen("media")
            readonly property bool shown: win.player && win.player.trackTitle !== ""
            anchors { left: clockPill.right; leftMargin: shown ? Theme.gap : -width; top: parent.top; topMargin: (Theme.barH - Theme.pillH) / 2 }
            opacity: shown ? 1 : 0
            visible: opacity > 0.01
            Behavior on anchors.leftMargin { NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.dur } }
            IconBtn {
                id: mediaBtn
                active: Ui.popup === "media" && Ui.screenName === win.sname
                icon: win.player && win.player.isPlaying ? "" : ""
                size: 11
                label: win.player ? (win.player.trackTitle.length > 28 ? win.player.trackTitle.slice(0, 27) + "…" : win.player.trackTitle) : ""
                onClicked: win.pop("media", mediaPill)
                onRightClicked: win.player && win.player.togglePlaying()
                onWheel: dy => { if (win.player) dy > 0 ? win.player.previous() : win.player.next(); }
            }
        }

        // ---- right ----
        Row {
            anchors { right: parent.right; rightMargin: Theme.gap; top: parent.top; topMargin: (Theme.barH - Theme.pillH) / 2 }
            spacing: Theme.gap
            Pill {
                id: trayPill
                readonly property var shown: SystemTray.items.values.filter(i => !/nm-applet|network ?manager/i.test((i.id || "") + " " + (i.title || "")))
                visible: shown.length > 0
                Repeater {
                    model: trayPill.shown
                    delegate: Item {
                        id: ti
                        required property var modelData
                        width: Theme.pillH - 4; height: width
                        anchors.verticalCenter: parent.verticalCenter
                        Image { anchors.centerIn: parent; width: 14; height: 14; source: ti.modelData.icon; sourceSize: Qt.size(32, 32) }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: m => {
                                if (m.button === Qt.RightButton && ti.modelData.hasMenu) ti.modelData.display(win, ti.mapToItem(null, 0, 0).x, Theme.barH);
                                else ti.modelData.activate();
                            }
                        }
                    }
                }
            }
            Pill {
                id: notifPill
                IconBtn {
                    icon: Notifs.dnd ? "\uf1f6" : "\uf0f3"
                    size: 12
                    label: Notifs.unread > 0 ? String(Notifs.unread) : ""
                    color: Notifs.dnd ? Theme.dim : Theme.fg
                    active: Ui.popup === "notif" && Ui.screenName === win.sname
                    onClicked: win.pop("notif", notifPill)
                    onRightClicked: Notifs.dnd = !Notifs.dnd
                }
                IconBtn { icon: "\uf03e"; size: 12; active: Ui.wallpaper; onClicked: Ui.toggleWallpaper() }
            }
            Pill {
                id: statusPill
                open: win.isOpen("wifi") || win.isOpen("bt") || win.isOpen("vol") || win.isOpen("bat")
                IconBtn {
                    id: wifiBtn
                    icon: Net.wired && !Net.ssid ? "" : Net.enabled ? "" : ""
                    color: Net.connected ? Theme.fg : Theme.dim
                    active: Ui.popup === "wifi" && Ui.screenName === win.sname
                    onClicked: win.pop("wifi", statusPill)
                    onRightClicked: Net.toggle()
                }
                IconBtn {
                    id: btBtn
                    icon: ""
                    active: Ui.popup === "bt" && Ui.screenName === win.sname
                    onClicked: win.pop("bt", statusPill)
                }
                IconBtn {
                    id: volBtn
                    icon: win.volIcon()
                    active: Ui.popup === "vol" && Ui.screenName === win.sname
                    onClicked: win.pop("vol", statusPill)
                    onRightClicked: Audio.toggleMute()
                    onWheel: dy => Audio.setVolume(Audio.volume + (dy > 0 ? 0.04 : -0.04))
                }
                IconBtn {
                    id: batBtn
                    icon: win.batIcon()
                    label: Sys.hasBattery ? Math.round(Sys.percent) + "%" : ""
                    color: Sys.hasBattery && !Sys.charging && Sys.percent < 15 ? Theme.danger : Theme.fg
                    active: Ui.popup === "bat" && Ui.screenName === win.sname
                    onClicked: win.pop("bat", statusPill)
                }
            }
            Pill {
                id: powerPill
                width: Theme.pillH
                open: false
                IconBtn {
                    id: pwBtn
                    icon: ""
                    size: 11
                    active: Ui.powermenu
                    onClicked: Ui.togglePower()
                }
            }
        }
    }
}
