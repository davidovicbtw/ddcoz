# ddcoz

A dark, bubble-style desktop shell for Hyprland, built with [Quickshell](https://quickshell.org).

- floating bubble bar with popups that grow out of the pills (wifi, bluetooth, volume, battery, clock, media)
- launcher with web search, notifications
- fullscreen power menu and wallpaper carousel with search and colour filters
- animated session lock screen (PAM), hyprlock fallback
- `ddcoz` CLI for settings and control

## Install (Arch Linux)

```sh
git clone https://github.com/davidovicbtw/ddcoz.git
cd ddcoz
./install.sh            # --no-deps to skip packages, --uninstall to remove
```

The installer prints the Hyprland autostart/bind lines to add. Put wallpapers in `~/Pictures/Wallpapers`.

## Usage

```sh
ddcoz run --replace   # start / restart
ddcoz list            # all settings
ddcoz set accent=#ff8a8a opacity=0.9
ddcoz popup wifi
ddcoz launcher
ddcoz lock
```

Shortcuts: power menu `qs -p ~/.config/quickshell/ddcoz ipc call ddcoz power`, wallpaper picker `... wallpaper`.

## Requirements

quickshell, awww, Hyprland, hyprlock, python + Pillow, kitty, NetworkManager, bluez, brightnessctl, wl-clipboard, upower, PipeWire, Inter and JetBrainsMono Nerd fonts.
