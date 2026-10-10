pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color bg: Qt.rgba(0.07, 0.075, 0.09, Config.opacity)
    readonly property color panel: Qt.rgba(0.085, 0.09, 0.11, Math.min(1, Config.opacity + 0.1))
    readonly property color card: Qt.rgba(1, 1, 1, 0.06)
    readonly property color cardHover: Qt.rgba(1, 1, 1, 0.12)
    readonly property color border: Qt.rgba(1, 1, 1, 0.09)
    readonly property color fg: "#f2f3f7"
    readonly property color dim: Qt.rgba(1, 1, 1, 0.55)
    readonly property color accent: Config.accent
    readonly property color accentText: "#0b0d14"
    readonly property color danger: "#ff6b6b"
    readonly property string font: "Inter"
    readonly property string icons: "JetBrainsMono Nerd Font"
    readonly property int barH: Config.barHeight
    readonly property int pillH: Config.barHeight - 10
    readonly property int gap: Config.gap
    readonly property int radius: Config.radius
    readonly property int dur: Config.animations ? 160 : 0
    readonly property int durSlow: Config.animations ? 240 : 0
}
