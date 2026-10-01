#!/usr/bin/env fish
# Deliberately restrict selection to this edition's separate directory.
set -l wallpaper_dir "$HOME/Pictures/Wallpapers/momiji-dots-normie"
if not set -q HYPRLAND_INSTANCE_SIGNATURE
    exit 0
end
if not command -q caelestia
    echo "caelestia is not installed." >&2
    exit 1
end
if not test -d "$wallpaper_dir"
    echo "Missing wallpaper directory: $wallpaper_dir" >&2
    exit 1
end
set -l images (find "$wallpaper_dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -print0 | string split0)
if test (count $images) -eq 0
    echo "No supported wallpapers in $wallpaper_dir" >&2
    exit 1
end
set -l chosen $images[(random 1 (count $images))]
caelestia wallpaper -f "$chosen"
or exit $status
caelestia scheme set -n dynamic
