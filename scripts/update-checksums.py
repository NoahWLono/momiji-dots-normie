#!/usr/bin/env python3
"""Regenerate a release manifest after reviewing intentional source changes."""
from __future__ import annotations
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
paths = []
for path in ROOT.rglob('*'):
    rel = path.relative_to(ROOT)
    if '.git' in rel.parts or '__pycache__' in rel.parts:
        continue
    if path.is_symlink():
        raise SystemExit(f'Refusing a symlink in the release: {rel}')
    if path.is_file() and rel.as_posix() != 'SHA256SUMS':
        paths.append(path)
lines = []
for path in sorted(paths):
    name = path.relative_to(ROOT).as_posix()
    if '\n' in name or '\r' in name:
        raise SystemExit('Unsupported newline in a release filename')
    lines.append(f'{hashlib.sha256(path.read_bytes()).hexdigest()}  {name}\n')
(ROOT/'SHA256SUMS').write_text(''.join(lines))
print(f'Wrote SHA256SUMS for {len(paths)} files. Review and commit the manifest with the changes.')
