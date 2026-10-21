#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DRY=0
APPLY=1
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY=1 ;;
        --no-apply) APPLY=0 ;;
        -h|--help) echo 'Usage: scripts/deploy-configs.sh [--dry-run] [--no-apply]'; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
    esac
done
if (( EUID == 0 && DRY == 0 )); then
    echo 'Run as your normal desktop user, not root.' >&2; exit 1
fi
CONFIG=${XDG_CONFIG_HOME:-"$HOME/.config"}
STATE=${XDG_STATE_HOME:-"$HOME/.local/state"}
BACKUP="$STATE/momiji-dots-normie/backups/$(date +%Y%m%d-%H%M%S)-$$"
if (( DRY == 0 )) && [[ ! -f "$CONFIG/hypr/hyprland.lua" ]]; then
    echo 'Expected an existing Caelestia Lua installation.' >&2
    echo 'Install Caelestia and test its Hyprland session first.' >&2
    exit 1
fi
deploy_file() {
    local src=$1 dst=$2 mode=${3:-644} backup tmp
    [[ -f "$src" ]] || { printf 'Missing source: %s\n' "$src" >&2; return 1; }
    if (( DRY )); then printf 'Install %s -> %s (mode %s)\n' "$src" "$dst" "$mode"; return; fi
    if [[ -d "$dst" && ! -L "$dst" ]]; then
        printf 'Refusing to replace a directory: %s\n' "$dst" >&2; return 1
    fi
    if [[ -f "$dst" && ! -L "$dst" ]] && cmp -s "$src" "$dst"; then return; fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        backup="$BACKUP/${dst#/}"
        mkdir -p -- "$(dirname "$backup")"
        cp -a -- "$dst" "$backup"
        printf 'Backup: %s\n' "$backup"
    fi
    mkdir -p -- "$(dirname "$dst")"
    tmp=$(mktemp "${dst}.normie.XXXXXX")
    if ! install -m "$mode" -- "$src" "$tmp"; then rm -f -- "$tmp"; return 1; fi
    # Replace a file/symlink atomically, never overwrite its former referent.
    if ! mv -Tf -- "$tmp" "$dst"; then rm -f -- "$tmp"; return 1; fi
}
deploy_file "$ROOT/home/caelestia/hypr-vars.lua" "$CONFIG/caelestia/hypr-vars.lua"
deploy_file "$ROOT/home/caelestia/hypr-user.lua" "$CONFIG/caelestia/hypr-user.lua"
deploy_file "$ROOT/home/fish/20-greeting.fish" "$CONFIG/fish/conf.d/20-greeting.fish"
deploy_file "$ROOT/home/fastfetch/config.jsonc" "$CONFIG/fastfetch/config.jsonc"
deploy_file "$ROOT/scripts/random-wallpaper.fish" "$HOME/.local/bin/normie-wallpaper.fish" 755
deploy_file "$ROOT/wallpapers/arch-horizon.png" "$HOME/Pictures/Wallpapers/momiji-dots-normie/arch-horizon.png"
deploy_file "$ROOT/home/fish/region-copy.fish" "$HOME/.local/bin/region-copy.fish"
if (( DRY )); then echo 'Dry run complete; nothing changed.'; exit 0; fi
if (( APPLY )) && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v caelestia >/dev/null && command -v hyprctl >/dev/null; then
    caelestia wallpaper -f "$HOME/Pictures/Wallpapers/momiji-dots-normie/arch-horizon.png"
    caelestia scheme set -n dynamic
    hyprctl reload
else
    echo 'Files installed. Log into Hyprland to apply the wallpaper.'
fi
printf 'Done. Any replaced files are under %s\n' "$BACKUP"
echo 'Other existing configuration files and wallpapers were not deleted.'
