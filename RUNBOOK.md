# Installation runbook

## 1. Scope and prerequisites

Use an already-installed, current Arch Linux system with a working network and
a normal user who can use sudo. The source machine used AMD graphics, the Linux
kernel, LUKS2, btrfs, and zram. Review AMD-specific packages on other hardware.
This edition does not partition disks or install Arch for you.

Save a recovery TTY, current desktop configuration, and important files before
changing your graphical session. A separate test user is the safest first test.

## 2. Inspect and validate

```sh
bash scripts/validate-repo.sh
python3 -m unittest discover -s tests -v
less packages.txt
less aur-packages.txt
bash scripts/install-packages.sh --dry-run
```

`packages.txt` is the installer's official-package input. `packages/pacman.txt`
is the retained alternate inventory and additionally includes `rustup`.
`aur-packages.txt` and `packages/aur.txt` are identical saved AUR inventories.
The generated `paru-debug` inventory entry is not sent to the AUR as an install
target. An existing paru installation is reused; otherwise the bootstrap uses
`paru-bin` after displaying its PKGBUILD and requesting confirmation.

The optional `packages/security*.txt` inventories are not required for the
desktop and are never installed automatically. Review availability and suitability
before using them. This repository adds no external package repositories.

## 3. Install packages and Caelestia

```sh
bash scripts/install-packages.sh
caelestia install --aur-helper paru
```

The package script uses `pacman -Syu`, leaves AUR review interactive, backs up
the zram configuration, and enables the source Bluetooth, power-profile, and
weekly trim services. It does not install the tracked pacman.conf, enable SSH,
enable a display manager, or install security inventories.

The Lua overlay expects `~/.config/hypr/hyprland.lua`, matching the inspected
source setup. Future upstream configuration changes may require adapting these
hooks. First launch the installed Hyprland session manually and confirm that
Caelestia, a terminal, networking, sound, and GUI authentication work.

## 4. Deploy the user overlay

```sh
bash scripts/deploy-configs.sh --dry-run
bash scripts/deploy-configs.sh
```

Use `--no-apply` to write files without requesting a running desktop reload.
The script respects `XDG_CONFIG_HOME` and `XDG_STATE_HOME`. Its wallpaper pool is
separate from other pictures. All replaced files have timestamped backups;
symlinks are backed up and replaced, rather than overwriting their old referents.
Other existing user customizations are deliberately not deleted. For a predictable
result, use a clean user profile rather than assuming an overlay erases old files.

## 5. Optional SDDM

```sh
bash scripts/enable-display-manager.sh --dry-run
bash scripts/enable-display-manager.sh
```

The script checks for a Hyprland session and asks whether you tested it. It refuses
to replace a different selected display manager without deliberate intervention.
It installs the supplied login baseline and late stock-theme override, preserves
backups, retires the old tty-autologin overrides with backups, and enables SDDM
for the next boot. It does not restart your active display manager.

On an existing machine, inspect `/etc/sddm.conf` and other drop-ins for conflicting
settings. The supplied configuration alone cannot guarantee that untracked local
configuration will not override it.

## 6. Retained system configuration, opt-in only

The following files are examples retained from the source machine, not a universal
installer:

| File | Review before use |
| --- | --- |
| `boot/arch.conf.template` | LUKS UUID, root mapping, `@` subvolume, discard choice |
| `boot/loader.conf` | systemd-boot layout, timeout and console settings |
| `etc/mkinitcpio.conf.d/momiji-encryption.conf` | Existing initramfs and hook ordering |
| `etc/hosts` | Hostname must match your own machine |
| `etc/rtw89.conf` | Only relevant hardware using the rtw89 driver |
| `etc/wifi-powersave.conf` | Apply only when diagnosing Wi-Fi power issues |
| `etc/pacman.conf` | Preserve any intentionally configured local repositories/options |

The source disk layout was an unencrypted EFI partition plus a LUKS2-encrypted
btrfs container with `@` and `@home`, and RAM-only zram swap rather than disk swap.
The template retains discard pass-through; review that choice against your privacy
requirements. This layout does not provide hibernation or encrypt the EFI partition.
Never install the unresolved `LUKS_UUID_PLACEHOLDER` boot entry. The overlay scripts
do not install boot files, change initramfs hooks, or regenerate the bootloader.

## 7. On-device acceptance checks

Test a normal login, lock/unlock, suspend/resume, terminal greeting, cursor in GTK
and Qt applications, wallpaper selection, GUI privilege prompts, audio, networking,
and reboot. Check `systemctl --user status hyprpolkitagent` and the journal when
GUI authentication fails. Offline tests do not replace these hardware/session checks.
