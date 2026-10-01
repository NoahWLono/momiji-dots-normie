#!/usr/bin/env bash
# Optional, generic terminal utilities. Not needed for the desktop.
set -Eeuo pipefail
case "${1:-}" in
    --dry-run) echo 'sudo pacman -Syu --needed asciiquarium cmatrix figlet fortune-mod lolcat sl'; exit 0 ;;
    '') ;;
    *) echo 'Usage: scripts/install-fun.sh [--dry-run]' >&2; exit 2 ;;
esac
(( EUID != 0 )) || { echo 'Run as a normal user.' >&2; exit 1; }
[[ -r /etc/arch-release ]] || { echo 'Arch Linux is required.' >&2; exit 1; }
sudo pacman -Syu --needed asciiquarium cmatrix figlet fortune-mod lolcat sl
