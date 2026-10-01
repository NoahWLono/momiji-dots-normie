#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DRY=0
case "${1:-}" in
    --dry-run) DRY=1 ;;
    '') ;;
    -h|--help) echo 'Usage: scripts/install-packages.sh [--dry-run]'; exit 0 ;;
    *) echo 'Unknown option.' >&2; exit 2 ;;
esac
(( $# <= 1 )) || { echo 'Too many arguments.' >&2; exit 2; }
if (( DRY == 0 )); then
    (( EUID != 0 )) || { echo 'Run as a normal user, not root.' >&2; exit 1; }
    [[ -r /etc/arch-release ]] || { echo 'This installer requires Arch Linux.' >&2; exit 1; }
fi
read_list() { awk '!/^[[:space:]]*(#|$)/ {sub(/[[:space:]]+#.*$/, ""); print $1}' "$1"; }
mapfile -t repo_packages < <(read_list "$ROOT/packages.txt")
# paru is bootstrapped separately. Debug split-package inventory is not an AUR target.
mapfile -t aur_packages < <(read_list "$ROOT/aur-packages.txt" | grep -Ev '^(paru|paru-bin|paru-debug|paru-bin-debug)$')
for pkg in "${repo_packages[@]}" "${aur_packages[@]}"; do
    [[ "$pkg" =~ ^[a-z0-9][a-z0-9@._+-]*$ ]] || { echo "Invalid package: $pkg" >&2; exit 1; }
done
if (( DRY )); then
    printf 'sudo pacman -Syu --needed'; printf ' %q' "${repo_packages[@]}"; printf '\n'
    echo 'Bootstrap paru-bin from its reviewed AUR PKGBUILD if paru is absent.'
    printf 'paru -S --needed'; printf ' %q' "${aur_packages[@]}"; printf '\n'
    echo 'Back up/install zram config; enable Bluetooth, power profiles, and weekly fstrim.'
    echo 'Security inventories are not installed by this desktop script.'
    exit 0
fi
sudo pacman -Syu --needed "${repo_packages[@]}"
if ! command -v paru >/dev/null 2>&1; then
    build_dir=$(mktemp -d)
    trap 'rm -rf -- "$build_dir"' EXIT
    git clone https://aur.archlinux.org/paru-bin.git "$build_dir/paru-bin"
    printf 'Review the bootstrap PKGBUILD at: %s/paru-bin/PKGBUILD\n' "$build_dir"
    cat "$build_dir/paru-bin/PKGBUILD"
    read -r -p 'Build and install this AUR helper? [y/N] ' answer
    [[ "$answer" == y || "$answer" == Y ]] || exit 1
    (cd "$build_dir/paru-bin" && makepkg -si)
fi
if ((${#aur_packages[@]})); then paru -S --needed "${aur_packages[@]}"; fi
if [[ -e /etc/systemd/zram-generator.conf ]]; then
    sudo cp -a /etc/systemd/zram-generator.conf "/etc/systemd/zram-generator.conf.bak.$(date +%Y%m%d-%H%M%S)-$$"
fi
sudo install -Dm644 "$ROOT/etc/zram-generator.conf" /etc/systemd/zram-generator.conf
sudo systemctl daemon-reload
sudo systemctl enable --now bluetooth.service power-profiles-daemon.service
sudo systemctl enable fstrim.timer
printf '\nPackages installed; zram takes effect after reboot.\n'
printf 'Next: caelestia install --aur-helper paru\n'
printf 'Then test Hyprland and run scripts/deploy-configs.sh.\n'
