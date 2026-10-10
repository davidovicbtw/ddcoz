//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "singletons"

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Scope {
                id: scope
                required property var modelData
                Strut { modelData: scope.modelData }
                Bar { modelData: scope.modelData }
                Launcher { modelData: scope.modelData }
                PowerMenu { modelData: scope.modelData }
                Wallpaper { modelData: scope.modelData }
            }
        }
    }
    Lock { id: lockScreen }
    Osd {}
    Clipboard {}
    Loader { active: Config.notifications; source: "Toasts.qml" }

    IpcHandler {
        target: "ddcoz"
        function ping(): string { return "pong"; }
        function launcher(): void { Ui.toggleLauncher(); }
        function search(text: string): void { Ui.openLauncher(text); }
        function popup(name: string): void {
            if (name === "") Ui.close();
            else Ui.request(name);
        }
        function lock(): void { lockScreen.lockNow(); }
        function lockdemo(): void { lockScreen.showDemo(); }
        function clipboard(): void { Ui.toggleClipboard(); }
        function osd(kind: string): void {
            if (kind === "bright") { Brightness.refresh(); Brightness.osdPending = true; }
        }
        function power(): void { Ui.togglePower(); }
        function wallpaper(): void { Ui.wallQuery = ""; Ui.toggleWallpaper(); }
        function wallsearch(text: string): void { Ui.wallQuery = text; Ui.wallpaper = false; Ui.togglePowerOff(); Ui.wallpaper = true; }
    }
}
