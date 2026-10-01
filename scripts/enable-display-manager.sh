#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
case "${1:-}" in
    --dry-run)
        echo 'Back up/install 10-momiji.conf and 99-normie.conf; enable password-required SDDM for next boot.'
        echo 'No profile pictures are copied. Other display managers must be disabled manually.'
        exit 0 ;;
    '') ;;
    -h|--help) echo 'Usage: scripts/enable-display-manager.sh [--dry-run]'; exit 0 ;;
    *) echo 'Unknown option.' >&2; exit 2 ;;
esac
(( $# == 0 )) || exit 2
(( EUID != 0 )) || { echo 'Run as your normal user, not root.' >&2; exit 1; }
command -v sddm >/dev/null || { echo 'Install SDDM first.' >&2; exit 1; }
[[ -f /usr/share/wayland-sessions/hyprland.desktop ]] || { echo 'Hyprland session file is missing.' >&2; exit 1; }
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.lua" ]] || { echo 'Install and test Caelestia first.' >&2; exit 1; }
if [[ -L /etc/systemd/system/display-manager.service ]]; then
    dm=$(basename "$(readlink -f /etc/systemd/system/display-manager.service)")
    [[ "$dm" == sddm.service ]] || { echo "Another display manager is selected: $dm. Disable it deliberately first." >&2; exit 1; }
fi
read -r -p 'Have you successfully tested a manual Hyprland session? [y/N] ' answer
[[ "$answer" == y || "$answer" == Y ]] || exit 1
stamp=$(date +%Y%m%d-%H%M%S)-$$
for conf in 10-momiji.conf 99-normie.conf; do
    target="/etc/sddm.conf.d/$conf"
    if [[ -e "$target" ]]; then sudo cp -a "$target" "$target.bak.$stamp"; fi
    sudo install -Dm644 "$ROOT/etc/sddm.conf.d/$conf" "$target"
done
# Retire the previous tty autologin overrides, preserving backups.
legacy=/etc/systemd/system/getty@tty1.service.d/autologin.conf
if [[ -f "$legacy" ]]; then sudo mv "$legacy" "$legacy.bak.$stamp"; fi
legacy="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/10-tty1-hyprland.fish"
if [[ -f "$legacy" ]]; then mv "$legacy" "$legacy.bak.$stamp"; fi
sudo systemctl daemon-reload
sudo systemctl set-default graphical.target
sudo systemctl enable sddm.service
echo 'Stock SDDM is enabled for the next boot; your current session was not restarted.'
echo 'Autologin is disabled in the supplied configs. Review any other SDDM overrides before rebooting.'
