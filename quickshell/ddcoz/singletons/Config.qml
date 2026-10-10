pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// User settings live in ~/.config/ddcoz/settings.json (edited by the `ddcoz` CLI).
Singleton {
    id: root
    readonly property alias data: adapter
    property string accent: adapter.accent
    property real opacity: adapter.opacity
    property int workspaces: adapter.workspaces
    property bool clock24: adapter.clock24
    property bool seconds: adapter.seconds
    property int barHeight: adapter.barHeight
    property int gap: adapter.gap
    property int radius: adapter.radius
    property bool notifications: adapter.notifications
    property bool animations: adapter.animations
    property string terminal: adapter.terminal
    property string search: adapter.search

    FileView {
        path: Quickshell.env("HOME") + "/.config/ddcoz/settings.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: adapter
            property string accent: "#7c9cff"
            property real opacity: 0.82
            property int workspaces: 5
            property bool clock24: true
            property bool seconds: false
            property int barHeight: 44
            property int gap: 8
            property int radius: 20
            property bool notifications: true
            property bool animations: true
            property string terminal: "kitty"
            property string search: "https://www.google.com/search?q="
        }
    }
}
