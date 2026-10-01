#!/usr/bin/env python3
"""Offline integrity checks; no network and no installed-desktop changes."""
from __future__ import annotations
import configparser
import json
from pathlib import Path
import re
import struct
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]

def packages(name: str) -> list[str]:
    values = []
    for line in (ROOT / name).read_text().splitlines():
        line = line.split('#', 1)[0].strip()
        if line:
            assert re.fullmatch(r'[a-z0-9][a-z0-9@._+\-]*', line), (name, line)
            values.append(line)
    assert len(values) == len(set(values)), f'Duplicate entries in {name}'
    return values

def check() -> None:
    required = {
        'README.md', 'RUNBOOK.md', 'CHECKLIST.md', 'SOURCE.md', 'PUBLISH.md',
        'home/caelestia/hypr-vars.lua', 'home/caelestia/hypr-user.lua',
        'home/fastfetch/config.jsonc', 'home/fish/20-greeting.fish',
        'scripts/deploy-configs.sh', 'scripts/install-packages.sh',
        'scripts/enable-display-manager.sh', 'scripts/random-wallpaper.fish',
        'scripts/publish-github.sh', 'publish.fish',
        'wallpapers/arch-horizon.svg', 'wallpapers/arch-horizon.png',
        'boot/arch.conf.template', 'boot/loader.conf',
    }
    for name in required:
        assert (ROOT / name).is_file(), f'Missing {name}'
    official = packages('packages.txt')
    assert {'hyprland', 'fish', 'fastfetch', 'adwaita-cursors', 'hyprpolkitagent'} <= set(official)
    assert set(packages('packages/pacman.txt')) == set(official) | {'rustup'}
    aur = packages('aur-packages.txt')
    assert aur == packages('packages/aur.txt')
    assert {'caelestia-cli', 'caelestia-shell'} <= set(aur)
    for name in ('packages/security.txt', 'packages/security-aur.txt'):
        packages(name)
    ff = json.loads((ROOT / 'home/fastfetch/config.jsonc').read_text())
    assert ff['logo']['source'] == 'arch'
    assert ff['logo']['type'] == 'builtin'
    data = (ROOT / 'wallpapers/arch-horizon.png').read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    assert struct.unpack('>II', data[16:24]) == (3840, 2160)
    svg = ET.parse(ROOT / 'wallpapers/arch-horizon.svg')
    for elem in svg.iter():
        assert elem.tag.split('}')[-1] not in {'script', 'image', 'foreignObject'}
        for key in elem.attrib:
            assert not key.lower().startswith('on')
    config = configparser.ConfigParser()
    config.read([ROOT/'etc/sddm.conf.d/10-momiji.conf', ROOT/'etc/sddm.conf.d/99-normie.conf'])
    assert config['Autologin']['User'] == ''
    assert config['Autologin']['Session'] == ''
    assert not config.getboolean('Autologin', 'Relogin')
    assert config['Theme']['Current'] == ''
    assert not config.getboolean('Theme', 'EnableAvatars')
    assert 'LUKS_UUID_PLACEHOLDER' in (ROOT / 'boot/arch.conf.template').read_text()
    assert 'sd-encrypt' in (ROOT/'etc/mkinitcpio.conf.d/momiji-encryption.conf').read_text()
    for p in ROOT.rglob('*'):
        rel = p.relative_to(ROOT)
        if '.git' in rel.parts or '__pycache__' in rel.parts:
            continue
        assert not p.is_symlink(), f'Unexpected symlink: {rel}'
        if not p.is_file():
            continue
        assert p.suffix not in {'.key', '.pem', '.p12'}, f'Unexpected credential file: {rel}'
        assert p.name != '.env' and not p.name.startswith('.env.'), f'Unexpected environment file: {rel}'
        if p.suffix == '.sh' or (p.suffix == '.fish' and ('scripts' in rel.parts or p.name == 'publish.fish')):
            assert p.stat().st_mode & 0o111, f'Not executable: {rel}'
        if p.suffix in {'.md', '.lua', '.sh', '.fish', '.conf', '.txt', '.jsonc', '.py', '.yml'}:
            text = p.read_text()
            assert '\x00' not in text and '\r' not in text, f'Unexpected encoding: {rel}'
    print(f'Structure: {len(official)} main packages, {len(aur)} AUR inventory entries; wallpaper and login checks passed.')

if __name__ == '__main__':
    check()
