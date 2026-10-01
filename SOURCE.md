# Source and scope

Desktop-focused derivative of `NoahWLono/momiji-dots`.

- Source: https://github.com/NoahWLono/momiji-dots
- Inspected main commit: `654d2ddf4c45dd40afece7a52b4b93f4e7445d63`
- Prepared: 2026-10-01
- Intended destination: `NoahWLono/momiji-dots-normie`

This is an independent snapshot, not a Git fork or history mirror. The parent
repository and the user's installed desktop are not modified by packaging.

## Retained

The source boot, initramfs, host, Wi-Fi, zram, and password-login baseline
configuration; the package inventories; Firefox as the browser override;
the Caelestia Lua configuration interface; graphical authentication-agent startup.

The two main repository inventories retain their original distinction:
`packages/pacman.txt` also contains `rustup`; `packages.txt` does not.
Both main inventories now include `adwaita-cursors`. One presentation-only
terminal utility was removed. The AUR and optional security inventories are
retained. Debug split packages are inventory entries, not standalone install targets.

## Replaced or omitted

Presentation assets, custom cursor and greeter builders, custom terminal-art
tooling, sound hooks, old screenshots, and presentation-specific documents are
not carried over. This edition uses an original vector wallpaper, Arch's built-in
terminal logo, Adwaita cursors, and SDDM's embedded greeter with avatars disabled.
The package-manager progress animation is disabled; its ordinary options remain.

The desktop deployer and validation suite are rebuilt for this file layout.
The separate security-workstation automation is outside this desktop-focused
edition; its package inventories remain available but are not installed by default.
The installation documentation is rewritten, rather than claiming that a
machine-specific disk-provisioning runbook is portable to every computer.

## Licensing and upstream software

No license file was present in the inspected source snapshot. This derivative
does not relabel inherited material under a newly chosen license. Caelestia,
Hyprland, Arch Linux, and third-party packages keep their own licenses and marks.
The vector wallpaper was created for this edition; it contains no external image
files, font files, embedded portraits, or third-party character artwork.

## Verification boundary

The included local tests validate files, shell parsing when interpreters are
available, and deployment behavior in isolated temporary home directories.
An interactive Hyprland session and live Arch/AUR package resolution are separate
on-device checks; neither is represented as completed by an offline test run.
