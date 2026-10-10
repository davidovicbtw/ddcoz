import QtQuick
import QtQuick.Effects

// ddcoz lock screen content: stacked clock that drops in, underline password, animated in and out.
Item {
    id: root
    property string wallpaper: ""
    property string font: "Inter"
    property string user: ""
    property string message: ""
    property bool busy: false
    property bool failed: false
    property bool demo: false
    property bool shown: false
    property bool leaving: false
    readonly property color accent: "#7c9cff"
    signal submit(string password)
    signal dismissed()
    signal gone()

    property string password: ""
    property date now: new Date()
    focus: true

    Component.onCompleted: { forceActiveFocus(); shown = true; }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }

    function fail() {
        root.password = "";
        root.failed = true;
        shake.restart();
        failTimer.restart();
    }
    function leave() { if (leaving) return; leaving = true; shown = false; leaveTimer.restart(); }
    Timer { id: leaveTimer; interval: 1050; onTriggered: root.gone() }
    property real kick: 0
    // 0 -> 1 on show, back on leave; drives the blur-in of the clock and password area
    property real appear: shown ? 1 : 0
    Behavior on appear { NumberAnimation { duration: root.shown ? 900 : 450; easing.type: root.shown ? Easing.OutCubic : Easing.InCubic } }
    // Typing never interrupts an animation: keys just add dots. Once typing pauses, the field plays one
    // zoom-out pulse (kick 1 -> 0). Fast typists see it after they stop; a running pulse is never restarted.
    onPasswordChanged: if (password.length > 0) typeIdle.restart()
    Timer { id: typeIdle; interval: 220; onTriggered: if (!pulse.running) pulse.start() }
    NumberAnimation { id: pulse; target: root; property: "kick"; from: 1; to: 0; duration: 480; easing.type: Easing.OutCubic }
    Timer { id: failTimer; interval: 1800; onTriggered: root.failed = false }

    readonly property string greeting: {
        const h = now.getHours();
        return h < 6 ? "good night" : h < 12 ? "good morning" : h < 18 ? "good afternoon" : "good evening";
    }

    Keys.onPressed: event => {
        if (root.busy || root.leaving) return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.submit(root.password);
        } else if (event.key === Qt.Key_Backspace) {
            root.password = root.password.slice(0, -1);
        } else if (event.key === Qt.Key_Escape) {
            if (root.password.length) root.password = ""; else if (root.demo) root.dismissed();
        } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32 && !(event.modifiers & Qt.ControlModifier)) {
            root.password += event.text;
            root.failed = false;
        }
    }

    // shared reveal curve: k goes 0 -> 1 after `delay` ms when the view is shown, quickly back on leave
    component Reveal: Item {
        id: rv
        property int delay: 0
        property int dur: 560
        property real k: root.shown ? 1 : 0
        Behavior on k {
            SequentialAnimation {
                PauseAnimation { duration: root.shown ? rv.delay : 0 }
                NumberAnimation { duration: root.shown ? rv.dur : 380; easing.type: root.shown ? Easing.OutBack : Easing.InCubic; easing.overshoot: 0.7 }
            }
        }
    }

    Rectangle { anchors.fill: parent; color: "#0c0d12" }

    // wallpaper: starts sharp, melts into blur + dim
    Item {
        anchors.fill: parent
        layer.enabled: true
        Image {
            id: bgImg
            anchors.fill: parent
            source: root.wallpaper ? "file://" + root.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: root.width
            sourceSize.height: root.height
            visible: false
        }
        MultiEffect {
            id: fx
            anchors.fill: parent
            source: bgImg
            blurEnabled: true
            blurMax: 64
            property real p: root.shown ? 1 : 0
            Behavior on p { NumberAnimation { duration: root.shown ? 800 : 800; easing.type: root.shown ? Easing.OutCubic : Easing.InOutCubic } }
            blur: p
            brightness: -0.22 * p
            saturation: 0.1 * p
            scale: root.leaving ? 1 : 1.06 - 0.06 * p
        }
    }

    // dark band on the left so the clock always reads
    Reveal {
        id: bandR
        dur: 900
        anchors.fill: parent
        Rectangle {
            width: 760; height: parent.height
            x: -width * (1 - Math.min(1, bandR.k))
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(0.03, 0.035, 0.055, 0.55) }
                GradientStop { position: 1; color: Qt.rgba(0.03, 0.035, 0.055, 0) }
            }
        }
    }

    // ---- clock ----
    Item {
        id: clock
        x: 130
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -40
        width: 560; height: 520

        layer.enabled: root.appear < 1
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 48
            blur: 1 - root.appear
        }

        // accent bar grows downward
        Reveal {
            id: barR
            delay: 80; dur: 600
            Rectangle {
                x: 0; y: 6
                width: 3; height: 150 * Math.min(1, barR.k)
                radius: 2; color: root.accent
                opacity: Math.min(1, barR.k * 2)
            }
        }

        Reveal {
            id: dateR
            delay: 160; dur: 650
            Text {
                x: 28; y: 2 + (1 - Math.min(1, dateR.k)) * -14
                opacity: Math.max(0, Math.min(1, dateR.k)) * 0.65
                text: Qt.formatDateTime(root.now, "dddd  ·  d MMMM").toUpperCase()
                color: "white"
                font.family: root.font; font.pixelSize: 14; font.weight: Font.DemiBold
                font.letterSpacing: 4
            }
        }

        // one digit: drops from above with overshoot, rolls when it changes
        component Digit: Item {
            id: dg
            property string ch: "0"
            property int delay: 0
            property real strength: 0.96
            property int px: 200
            width: px * 0.62; height: px * 1.05
            Reveal {
                id: r
                delay: dg.delay; dur: 700
            }
            property string shownCh: ch
            onChChanged: roll.restart()
            SequentialAnimation {
                id: roll
                NumberAnimation { target: glyph; property: "rollY"; to: dg.px * 0.25; duration: 160; easing.type: Easing.InCubic }
                ScriptAction { script: { dg.shownCh = dg.ch; glyph.rollY = -dg.px * 0.25; } }
                NumberAnimation { target: glyph; property: "rollY"; to: 0; duration: 360; easing.type: Easing.OutBack }
            }
            Text {
                id: glyph
                property real rollY: 0
                anchors.horizontalCenter: parent.horizontalCenter
                y: -dg.px * 0.07 + (1 - r.k) * -dg.px * 0.9 + rollY
                opacity: Math.max(0, Math.min(1, r.k * 1.6)) * (1 - Math.abs(rollY) / (dg.px * 0.25))
                text: dg.shownCh
                color: Qt.rgba(1, 1, 1, dg.strength)
                font.family: root.font; font.pixelSize: dg.px; font.weight: Font.Bold
            }
        }

        Row {
            x: 22; y: 30
            spacing: 4
            Digit { ch: Qt.formatDateTime(root.now, "HH")[0]; delay: 200 }
            Digit { ch: Qt.formatDateTime(root.now, "HH")[1]; delay: 260 }
        }
        Row {
            x: 22; y: 250
            spacing: 4
            Digit { ch: Qt.formatDateTime(root.now, "mm")[0]; delay: 340; strength: 0.34 }
            Digit { ch: Qt.formatDateTime(root.now, "mm")[1]; delay: 400; strength: 0.34 }
        }
    }

    // ---- password ----
    Item {
        id: pw
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 64
        width: 300; height: 110

        layer.enabled: root.appear < 1
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 48
            blur: 1 - root.appear
        }

        Reveal {
            id: greetR
            delay: 480; dur: 650
            Text {
                x: (pw.width - width) / 2
                y: 8 + (1 - Math.min(1, greetR.k)) * 16
                opacity: Math.max(0, Math.min(1, greetR.k)) * 0.55
                text: root.greeting + ", " + root.user
                color: "white"
                font.family: root.font; font.pixelSize: 14; font.weight: Font.Medium
            }
        }

        Item {
            id: pwBox
            anchors.horizontalCenter: parent.horizontalCenter
            y: 40
            width: parent.width; height: 44
            transformOrigin: Item.Center
            scale: 1 + 0.07 * root.kick

            // dots
            Row {
                id: dots
                x: (pwBox.width - width) / 2
                y: (pwBox.height - height) / 2
                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                spacing: 9
                Repeater {
                    model: root.password.length
                    delegate: Item {
                        id: dot
                        width: 9; height: 9
                        property real k: 0
                        Component.onCompleted: k = 1
                        Behavior on k { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        // new dot fades in while sliding from the right
                        Rectangle {
                            width: 9; height: 9; radius: 5
                            scale: 0.5 + 0.5 * dot.k
                            opacity: dot.k
                            color: root.failed ? "#ff8a8a" : "white"
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: root.password.length === 0
                opacity: root.busy ? 0.0 : 0.45
                text: root.failed ? "wrong password" : "enter password"
                color: root.failed ? "#ff8a8a" : "white"
                font.family: root.font; font.pixelSize: 14
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // underline: grows from the centre, glows while typing, shakes on failure
            Reveal {
                id: lineR
                delay: 420; dur: 650
                Rectangle {
                    id: line
                    x: (pwBox.width - width) / 2 + shakeX
                    y: pwBox.height
                    property real shakeX: 0
                    width: pw.width * Math.max(0, Math.min(1, lineR.k)) * (root.password.length > 0 ? 1.0 : 0.92)
                    Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                    height: 2 + 2 * root.kick; radius: 2
                    color: root.failed ? "#ff6b6b" : root.busy ? root.accent : Qt.tint(Qt.rgba(1, 1, 1, root.password.length > 0 ? 0.85 : 0.35), Qt.rgba(0.49, 0.61, 1, 0.9 * root.kick))
                    Behavior on color { ColorAnimation { duration: 220 } }
                }
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: line; property: "shakeX"; to: -16; duration: 55 }
                    NumberAnimation { target: line; property: "shakeX"; to: 14; duration: 90 }
                    NumberAnimation { target: line; property: "shakeX"; to: -9; duration: 80 }
                    NumberAnimation { target: line; property: "shakeX"; to: 5; duration: 70 }
                    NumberAnimation { target: line; property: "shakeX"; to: 0; duration: 60 }
                }
            }
            // busy shimmer while PAM checks
            Rectangle {
                visible: root.busy
                y: pwBox.height; height: 2; width: 70; radius: 1
                color: "white"; opacity: 0.9
                SequentialAnimation on x {
                    running: root.busy; loops: Animation.Infinite
                    NumberAnimation { from: 0; to: pwBox.width - 70; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { from: pwBox.width - 70; to: 0; duration: 600; easing.type: Easing.InOutSine }
                }
            }
        }
    }
}
