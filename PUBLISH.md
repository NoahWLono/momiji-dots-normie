# Publish this snapshot

From the unpacked repository root:

```fish
fish publish.fish --dry-run
fish publish.fish
```

Required tools: Git, GitHub CLI (`gh`), Python 3, Bash, and `sha256sum`.
The Fish entry point is optional; `bash scripts/publish-github.sh` also works.
On Arch, install missing tools with a full package transaction, for example:

```sh
sudo pacman -Syu --needed git github-cli python fish
```

The script verifies the release checksums, authenticates with the GitHub CLI,
checks for the `NoahWLono` account, initializes one clean local commit, creates
`NoahWLono/momiji-dots-normie` as public, pushes `main`, and reads back its SHA.
If sign-in is required, use the GitHub CLI's browser flow. Never paste a token
into a script, dotfile, issue, or chat.

An already-created empty destination is supported. A different nonempty history,
private destination, unexpected origin, wrong account, or imported Git history
causes a refusal rather than an overwrite. A retry after successful publication
recognizes the matching commit. No force-push is used.

The script adds the files in this unpacked directory to its new repository. Use a
fresh extraction, not a directory mixed with personal files. It never deploys the
dotfiles or changes the original `momiji-dots` repository. It does not change global
Git identity or credential-helper settings. GitHub CLI authentication itself may
store credentials in its normal secure storage.

The validation workflow requires permission to push workflow files. If GitHub
reports that permission is missing, authorize it through:

```sh
gh auth refresh --hostname github.com --scopes workflow
```

Then rerun the publisher. A failure can leave a newly created empty repository;
the script explicitly reports this rather than claiming a completed push.

The included workflow has no deployment, package installation, or publishing step.
It validates changes on GitHub after publication.

## Maintainer changes

Release checksums are intentionally strict. After reviewing intended source changes,
regenerate them before testing or publishing a refreshed snapshot:

```sh
python3 scripts/update-checksums.py
bash scripts/validate-repo.sh
python3 -m unittest discover -s tests -v
```

The initial publisher is intentionally limited to a single clean initial commit.
After the repository exists, maintain it with ordinary reviewed Git commits and
normal non-force pushes rather than using the initial publisher for later history.
