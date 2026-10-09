import QtQuick
import Quickshell
import Quickshell.Wayland
import "singletons"

// Invisible strip that reserves the bar's space so windows never sit underneath it.
PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barH
    exclusiveZone: Theme.barH
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "ddcoz-strut"
}
