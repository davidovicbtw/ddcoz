pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property string popup: ""
    property string screenName: ""
    // geometry of the bubble the popup grows out of (screen coords)
    property rect origin: Qt.rect(0, 0, 0, 0)
    property bool launcher: false
    property bool powermenu: false
    property bool wallpaper: false
    property string wallQuery: ""
    property rect logoRect: Qt.rect(6, 3, 24, 24)
    signal request(string name)
    property string query: ""

    function toggle(name, rect, screen) {
        launcher = false; powermenu = false; wallpaper = false;
        if (popup === name && screenName === screen) { popup = ""; return; }
        origin = rect;
        screenName = screen;
        popup = name;
    }
    function close() { popup = ""; }
    function togglePower() { popup = ""; launcher = false; wallpaper = false; powermenu = !powermenu; }
    function togglePowerOff() { popup = ""; launcher = false; powermenu = false; }
    function toggleWallpaper() { popup = ""; launcher = false; powermenu = false; wallpaper = !wallpaper; }
    function toggleLauncher() { popup = ""; query = ""; launcher = !launcher; }
    function openLauncher(text) { popup = ""; query = text; launcher = false; launcher = true; }
}
