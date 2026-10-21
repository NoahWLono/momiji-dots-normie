# momiji-dots-normie

**Arch Linux + Hyprland + Caelestia. A clean, minimal desktop.**

![Arch Horizon wallpaper](wallpapers/arch-horizon.png)

A desktop-focused edition of Momiji's configuration, with an abstract 4K
wallpaper, the standard Arch terminal logo, Adwaita cursors, a quiet login,
and a stock password-required SDDM greeter. No account credentials or user
portraits are bundled. This is a dotfile overlay, not an operating-system ISO.

## Install on an existing Arch system

Read [RUNBOOK.md](RUNBOOK.md) before making changes. Commands run as your normal
user; individual system operations request `sudo` where needed.

```sh
git clone https://github.com/NoahWLono/momiji-dots-normie.git
cd momiji-dots-normie
bash scripts/validate-repo.sh
bash scripts/install-packages.sh --dry-run
bash scripts/install-packages.sh
caelestia install --aur-helper paru
# Log into a working Hyprland/Caelestia session before continuing.
bash scripts/deploy-configs.sh --dry-run
bash scripts/deploy-configs.sh
```

Package installation performs a full system upgrade and can install large
applications. Review the inventories first. AUR builds remain interactive.
Package names are a source snapshot, not a guarantee of future availability.

Already running Caelestia? Skip package provisioning after checking the required
`fish`, `fastfetch`, `adwaita-cursors`, and `hyprpolkitagent` dependencies. Use only
the deployer to install the overlay. It backs up replaced files and does not
write to `/etc`, partition disks, remove other wallpapers, or enable a login manager.

## What is included

| Path | Purpose |
| --- | --- |
| `home/caelestia/` | User-owned Lua overrides, Firefox, cursor, startup hook |
| `home/fish/` | Interactive fastfetch greeting |
| `home/fastfetch/` | Standard Arch logo and system summary without user/IP modules |
| `wallpapers/` | Original 3840 x 2160 PNG plus editable SVG source |
| `packages.txt`, `aur-packages.txt` | Main package inventories |
| `packages/` | Alternate saved inventory and optional security-tool inventories |
| `boot/`, `etc/` | Retained machine configuration and reviewed deployment examples |
| `scripts/` | Install, deploy, wallpaper rotation, validation, and publishing |
| `tests/` | Isolated deployment and integrity checks |

The optional security inventories are not installed by the desktop installer.
Use any such tools only where you have authorization.

## Wallpaper rotation

Only images placed in `~/Pictures/Wallpapers/momiji-dots-normie/` are selected.
One wallpaper is supplied; adding PNG, JPEG, or WebP files enables variety on
subsequent logins. Existing images elsewhere are never added to the rotation.

```fish
fish ~/.local/bin/normie-wallpaper.fish
```

## Optional graphical login

After manually testing Hyprland:

```sh
bash scripts/enable-display-manager.sh
```

This enables SDDM for the next boot without restarting the current desktop.
It backs up its target files, does not copy a profile portrait, and supplies
an explicit no-autologin baseline. Review other local SDDM overrides yourself.

## Validation and provenance

```sh
bash scripts/validate-repo.sh
python3 -m unittest discover -s tests -v
sha256sum -c SHA256SUMS
```

See [SOURCE.md](SOURCE.md) for the pinned source, retained settings, intentional
scope changes, licensing status, and limits of offline verification.
[APPLY-OVERLAY.md](APPLY-OVERLAY.md) covers backup and rollback.

## Publish an unpacked release

The archive contains no previous Git history. From its root, run:

```fish
fish publish.fish
```

The publisher authenticates through the GitHub CLI, verifies the expected account,
creates `NoahWLono/momiji-dots-normie` as a public repository when absent, and pushes
a clean `main` branch. It refuses to overwrite a different existing history and
never writes to the source repository. See [PUBLISH.md](PUBLISH.md).

## Clipboard-only screenshots



Press **Ctrl + Shift + S** to select a screen region.

Release the mouse to copy the PNG to the clipboard.

No screenshot is saved to disk. Escape cancels.



Uses Fish, grim, slurp, and wl-clipboard.

The shortcut lives in `home/caelestia/hypr-user.lua`.

The deployer installs `home/fish/region-copy.fish`.
