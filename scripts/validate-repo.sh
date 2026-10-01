#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
while IFS= read -r -d '' file; do bash -n "$file"; done < <(find "$ROOT/scripts" -type f -name '*.sh' -print0)
if command -v fish >/dev/null 2>&1; then
    while IFS= read -r -d '' file; do fish --no-execute "$file"; done < <(find "$ROOT" -path "$ROOT/.git" -prune -o -type f -name '*.fish' -print0)
else
    echo 'SKIP: Fish interpreter unavailable; Fish syntax was not checked.'
fi
if command -v luac >/dev/null 2>&1; then
    luac -p "$ROOT/home/caelestia/hypr-user.lua"
    luac -p "$ROOT/home/caelestia/hypr-vars.lua"
else
    echo 'SKIP: luac unavailable; Lua syntax was not checked.'
fi
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "$ROOT"/scripts/*.sh
else
    echo 'SKIP: shellcheck unavailable.'
fi
python3 "$ROOT/tests/check_structure.py"
echo 'Available structural checks passed. Live desktop and package resolution are separate checks.'
