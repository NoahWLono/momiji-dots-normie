#!/usr/bin/env python3
"""Reject extra or missing files in a release before creating public history."""
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
entries = set()
for line in (root / "SHA256SUMS").read_text().splitlines():
    digest, name = line.split("  ", 1)
    if len(digest) != 64 or any(c not in "0123456789abcdef" for c in digest):
        raise SystemExit("Malformed release checksum")
    path = Path(name)
    if path.is_absolute() or ".." in path.parts or name in entries:
        raise SystemExit("Unsafe or duplicate checksum path")
    entries.add(name)
actual = set()
for path in root.rglob("*"):
    relative = path.relative_to(root)
    if ".git" in relative.parts or "__pycache__" in relative.parts:
        continue
    if path.is_file() or path.is_symlink():
        actual.add(relative.as_posix())
expected = entries | {"SHA256SUMS"}
if actual != expected:
    raise SystemExit(f"Release file set changed. Extra: {sorted(actual-expected)}; missing: {sorted(expected-actual)}")
print("Release file set matches the checksum manifest.")
