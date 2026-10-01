#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TARGET=NoahWLono/momiji-dots-normie
EXPECTED_OWNER=NoahWLono
REMOTE="https://github.com/$TARGET.git"
case "${1:-}" in
    --dry-run)
        printf 'Validate %s\nVerify GitHub account %s\n' "$ROOT" "$EXPECTED_OWNER"
        printf 'Initialize a fresh main history here; create public %s if absent; push without force.\n' "$TARGET"
        echo 'The source repository and installed desktop will not be modified.'
        exit 0 ;;
    '') ;;
    -h|--help) echo 'Usage: fish publish.fish [--dry-run]'; exit 0 ;;
    *) echo 'Unknown option.' >&2; exit 2 ;;
esac
(( $# == 0 )) || exit 2
for cmd in git gh python3 sha256sum; do
    command -v "$cmd" >/dev/null || { echo "Required command missing: $cmd" >&2; exit 1; }
done
bash "$ROOT/scripts/validate-repo.sh"
python3 "$ROOT/tests/check_release.py" "$ROOT"
(cd "$ROOT" && sha256sum --status -c SHA256SUMS) || { echo 'Archive files changed or checksum verification failed.' >&2; exit 1; }
if ! gh auth status --hostname github.com >/dev/null 2>&1; then
    echo 'Sign into the intended GitHub account in the browser opened by gh.'
    gh auth login --hostname github.com --git-protocol https --web --scopes repo,workflow
fi
login=$(gh api user --jq .login)
[[ "$login" == "$EXPECTED_OWNER" ]] || {
    printf 'Signed in as %s, expected %s. Switch GitHub accounts before publishing.\n' "$login" "$EXPECTED_OWNER" >&2
    exit 1
}
# Check the destination before initializing local history. An inaccessible
# repository is not assumed to be absent: creation will fail closed if needed.
repo_exists=0
if metadata=$(gh api "repos/$TARGET" --jq '[.owner.login, (.private|tostring), (.fork|tostring)] | @tsv' 2>/dev/null); then
    repo_exists=1
    [[ "$metadata" == "$EXPECTED_OWNER"$'\tfalse\tfalse' ]] || {
        echo 'Existing destination is not the expected public, independent repository.' >&2; exit 1;
    }
fi
if [[ -e "$ROOT/.git" && ! -d "$ROOT/.git" ]]; then
    echo 'Refusing a linked worktree or unexpected .git file.' >&2; exit 1
fi
if [[ -d "$ROOT/.git" ]]; then
    [[ $(git -C "$ROOT" rev-parse --show-toplevel) == "$ROOT" ]] || exit 1
    [[ $(git -C "$ROOT" branch --show-current) == main ]] || { echo 'Expected main branch.' >&2; exit 1; }
    [[ $(git -C "$ROOT" rev-list --count HEAD) == 1 ]] || { echo 'Refusing to publish an imported or extended history.' >&2; exit 1; }
    [[ -z $(git -C "$ROOT" status --porcelain) ]] || { echo 'Local tree is not clean.' >&2; exit 1; }
else
    user_id=$(gh api user --jq .id)
    git init --initial-branch=main "$ROOT"
    git -C "$ROOT" add -- .
    # Per-command identity; no changes to global Git settings.
    git -C "$ROOT" -c "user.name=$login" -c "user.email=$user_id+$login@users.noreply.github.com" \
        commit -m 'Initial Arch Linux, Hyprland and Caelestia desktop snapshot'
fi
local_sha=$(git -C "$ROOT" rev-parse HEAD)
# Guard against accidentally pushing to another repository after a retry.
if existing=$(git -C "$ROOT" remote get-url origin 2>/dev/null); then
    [[ "$existing" == "$REMOTE" ]] || { echo "Unexpected origin; refusing: $existing" >&2; exit 1; }
else
    git -C "$ROOT" remote add origin "$REMOTE"
fi
if (( repo_exists )); then
    branches=$(gh api "repos/$TARGET/branches" --paginate --jq '.[].commit.sha')
    tags=$(gh api "repos/$TARGET/tags" --paginate --jq '.[].commit.sha')
    if [[ -n "$branches" || -n "$tags" ]]; then
        remote_main=$(gh api "repos/$TARGET/git/ref/heads/main" --jq .object.sha 2>/dev/null || true)
        if [[ "$remote_main" == "$local_sha" && "$branches" == "$local_sha" && -z "$tags" ]]; then
            printf 'Already published: https://github.com/%s/tree/main\nCommit: %s\n' "$TARGET" "$local_sha"
            exit 0
        fi
        echo 'Destination already has a different history. Refusing to overwrite it.' >&2
        exit 1
    fi
else
    gh repo create "$TARGET" --public \
        --description 'Arch Linux, Hyprland and Caelestia dotfiles with a minimal geometric theme.'
fi
# Credential helper is scoped to this command. No token is printed or saved here.
if ! git -C "$ROOT" -c credential.helper= -c 'credential.helper=!gh auth git-credential' push --set-upstream origin main; then
    echo 'The remote may have been created, but publication did not complete.' >&2
    echo 'Review the Git error. A workflow-permission error can be resolved with:' >&2
    echo '  gh auth refresh --hostname github.com --scopes workflow' >&2
    echo 'Then rerun the same publisher. Nothing is force-pushed.' >&2
    exit 1
fi
remote_sha=$(gh api "repos/$TARGET/git/ref/heads/main" --jq .object.sha)
[[ "$remote_sha" == "$local_sha" ]] || { echo 'Remote commit verification failed.' >&2; exit 1; }
printf '\nPublished: https://github.com/%s/tree/main\nCommit: %s\n' "$TARGET" "$remote_sha"
