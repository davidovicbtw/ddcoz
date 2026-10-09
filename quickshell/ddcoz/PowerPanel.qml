import QtQuick
import QtQuick.Layouts
import "singletons"

Panel {
    id: p
    name: "power"
    panelWidth: 260
    property string confirm: ""
    onOpened: confirm = ""
    Timer { id: reset; interval: 3000; onTriggered: p.confirm = "" }

    component Action: Row2 {
        id: a
        required property string key
        property string cmd: ""
        property bool risky: false
        Layout.fillWidth: true
        subtitle: p.confirm === key ? "Click again to confirm" : ""
        iconColor: risky ? Theme.danger : Theme.fg
        highlighted: p.confirm === key
        onClicked: {
            if (risky && p.confirm !== key) { p.confirm = key; reset.restart(); return; }
            Ui.close();
            Sys.run(cmd);
        }
    }
    Text { text: "Session"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 16; font.weight: Font.DemiBold }
    Action { key: "lock"; icon: ""; title: "Lock"; cmd: "$HOME/.local/bin/ddcoz-lock" }
    Action { key: "suspend"; icon: ""; title: "Sleep"; cmd: "systemctl suspend" }
    Action { key: "logout"; icon: ""; title: "Log out"; risky: true; cmd: "hyprctl dispatch 'hl.dsp.exit()' || hyprctl dispatch exit" }
    Action { key: "reboot"; icon: ""; title: "Restart"; risky: true; cmd: "systemctl reboot" }
    Action { key: "off"; icon: ""; title: "Shut down"; risky: true; cmd: "systemctl poweroff" }
}
