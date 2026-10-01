# Build validation

Prepared 2026-10-01 from source commit
`654d2ddf4c45dd40afece7a52b4b93f4e7445d63`.

## Passed locally

- Bash syntax for all shell scripts.
- JSON, PNG dimensions/signature, SVG structure, package-name syntax, and duplicate checks.
- Supplied SDDM embedded-theme, avatar-disabled, and no-autologin configuration checks.
- Ten non-root isolated deployment tests, including dry-run, backup, idempotency,
  symlink referent preservation, XDG directories, paths with spaces, and a separate
  wallpaper pool.
- Seven publisher tests using real local Git with mocked GitHub and network push
  operations: destination selection, wrong-account refusal, conflicting-history
  refusal, modified/extra-file refusal, idempotency, and failed-push retry.
- Source blob-SHA matches for eleven copied source files: both boot files, hosts,
  both Wi-Fi snippets, zram, the baseline SDDM file, the initramfs drop-in, the AUR
  inventory, and both optional security inventories.
- Text/path presentation audit and manual inspection of the new wallpaper preview.

The main official-package inventory has 134 entries. The alternate saved inventory
has 135, retaining its additional `rustup` entry. The AUR inventory has 21 entries;
the installer treats the helper and debug split-package entries separately.

## Not completed here

- Fish syntax, Lua syntax, and ShellCheck: the corresponding tools were unavailable
  in the build container. The validation script reports these skips explicitly;
  the included GitHub workflow installs the checkers before running validation.
- A live Arch/AUR dependency-resolution or package-installation test.
- An interactive Hyprland/Caelestia session, login, suspend, or hardware test.
- A real GitHub repository creation or push. Local publisher tests use mocks and
  are not evidence of publication. Run the publisher in an authenticated environment.

`SHA256SUMS` verifies the original packaged files. After reviewing deliberate source
changes, run `python3 scripts/update-checksums.py`, rerun tests, and commit the updated
manifest. Do not use a checksum refresh to conceal unexpected or unreviewed files.
