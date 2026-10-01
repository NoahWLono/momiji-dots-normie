# Apply and roll back

Run as the normal desktop user, not with sudo:

```sh
bash scripts/deploy-configs.sh --dry-run
bash scripts/deploy-configs.sh --no-apply
```

The deployer prints every backup path. Backups are stored beneath
`${XDG_STATE_HOME:-~/.local/state}/momiji-dots-normie/backups/<timestamp>-<pid>/`.
Within that directory the original absolute path is reproduced without its
leading slash. For example, a file formerly at `/home/alex/.config/caelestia/hypr-vars.lua`
is stored under `home/alex/.config/caelestia/hypr-vars.lua` within the backup.

To roll back a replaced file, exit the affected application, inspect the backup,
remove only the replacement file, and copy the backup to its original location
with `cp -a`. Removing the replacement first also restores a backed-up symlink
correctly. Files that did not exist before deployment have no backup and may be
removed individually. Do not delete the whole `~/.config` directory.

The deployer changes exactly these user-facing targets:

- Caelestia `hypr-vars.lua` and `hypr-user.lua`.
- Fish `conf.d/20-greeting.fish` and fastfetch `config.jsonc`.
- `~/.local/bin/normie-wallpaper.fish`.
- `~/Pictures/Wallpapers/momiji-dots-normie/arch-horizon.png`.

The separate package and display-manager scripts make explicit system changes.
Their configuration backups sit next to their original files with timestamped
`.bak.*` suffixes. Enabling a service and installing a package are not undone by
restoring a dotfile; review those changes separately.
