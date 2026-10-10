#!/usr/bin/env bash
# ddcoz installer (Arch Linux + Hyprland). Usage: ./install.sh [--no-deps] [--uninstall]
set -euo pipefail
cd "$(dirname "$0")"

QS_DIR="$HOME/.config/quickshell/ddcoz"
CFG_DIR="$HOME/.config/ddcoz"
BIN_DIR="$HOME/.local/bin"
BINS=(ddcoz ddcoz-lock ddcoz-wallcolors ddcoz-wallpaper-restore ddcoz-shot)
PKGS=(quickshell awww hyprland hyprlock python python-pillow kitty networkmanager bluez-utils
      brightnessctl wl-clipboard cliphist fd grim slurp libnotify power-profiles-daemon
      xdg-utils upower pipewire inter-font ttf-jetbrains-mono-nerd)

say() { printf '\033[1;34m::\033[0m %s\n' "$*"; }

if [[ "${1:-}" == "--uninstall" ]]; then
    ddcoz stop 2>/dev/null || true
    rm -rf "$QS_DIR"
    for b in "${BINS[@]}"; do rm -f "$BIN_DIR/$b"; done
    say "removed ddcoz (settings and wallpapers in $CFG_DIR / ~/Pictures/Wallpapers kept)"
    exit 0
fi

if [[ "${1:-}" != "--no-deps" ]]; then
    command -v pacman >/dev/null || { echo "pacman not found: install the dependencies yourself and use --no-deps"; exit 1; }
    say "installing dependencies"
    repo=(); aur=()
    for p in "${PKGS[@]}"; do
        pacman -Qq "$p" >/dev/null 2>&1 && continue
        if pacman -Si "$p" >/dev/null 2>&1; then repo+=("$p"); else aur+=("$p"); fi
    done
    ((${#repo[@]})) && sudo pacman -S --needed "${repo[@]}"
    if ((${#aur[@]})); then
        helper=$(command -v paru || command -v yay || true)
        if [[ -n "$helper" ]]; then "$helper" -S --needed "${aur[@]}"
        else echo "install these from the AUR yourself: ${aur[*]}"; fi
    fi
fi

say "copying files"
mkdir -p "$(dirname "$QS_DIR")" "$CFG_DIR" "$BIN_DIR" "$HOME/Pictures/Wallpapers"
if [[ -d "$QS_DIR" ]]; then
    mv "$QS_DIR" "$QS_DIR.bak.$(date +%s)"
    say "existing install moved to $QS_DIR.bak.*"
fi
cp -r quickshell/ddcoz "$QS_DIR"
install -m755 bin/* "$BIN_DIR/"
[[ -f "$CFG_DIR/hyprlock.conf" ]] || cp config/hyprlock.conf "$CFG_DIR/"

case ":$PATH:" in *":$BIN_DIR:"*) ;; *) echo "note: add $BIN_DIR to your PATH" ;; esac

cat <<MSG

Done. Add this to your Hyprland config to autostart it:

  hyprlang (hyprland.conf):
    exec-once = ~/.local/bin/ddcoz run --replace
    exec-once = ~/.local/bin/ddcoz-wallpaper-restore
    bind = SUPER, Space, exec, ~/.local/bin/ddcoz launcher
    bind = SUPER, L, exec, ~/.local/bin/ddcoz-lock
    bind = SUPER, V, exec, qs -p ~/.config/quickshell/ddcoz ipc call ddcoz clipboard
    exec-once = wl-paste --watch cliphist store

  lua config:
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/ddcoz run --replace")
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/ddcoz-wallpaper-restore")
    hl.bind("SUPER + Space", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/ddcoz launcher"))
    hl.bind("SUPER + L", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/ddcoz-lock"))
    hl.bind("SUPER + V", hl.dsp.exec_cmd("qs -p ~/.config/quickshell/ddcoz ipc call ddcoz clipboard"))
    hl.exec_cmd("wl-paste --watch cliphist store")

Put wallpapers in ~/Pictures/Wallpapers, then start it with: ddcoz run
MSG
