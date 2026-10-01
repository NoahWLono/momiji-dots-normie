from __future__ import annotations
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT/'scripts/deploy-configs.sh'

class DeploymentTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix='normie-test-')
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)/'home with spaces'
        self.home.mkdir()
        self.config = self.home/'.config'
        (self.config/'hypr').mkdir(parents=True)
        (self.config/'hypr/hyprland.lua').write_text('-- test fixture\n')
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.config),
                        XDG_STATE_HOME=str(self.home/'.local/state'))
        self.env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)

    def run_script(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(['bash', str(SCRIPT), *args], env=self.env,
                              text=True, capture_output=True, timeout=15)

    def require_user(self) -> None:
        if os.geteuid() == 0:
            self.skipTest('Real deployment tests run as a non-root user, as required by the deployer.')

    def test_dry_run_does_not_write(self) -> None:
        before = sorted(str(p.relative_to(self.home)) for p in self.home.rglob('*'))
        result = self.run_script('--dry-run')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('nothing changed', result.stdout)
        self.assertEqual(before, sorted(str(p.relative_to(self.home)) for p in self.home.rglob('*')))

    def test_unknown_option_fails(self) -> None:
        self.assertEqual(self.run_script('--not-an-option').returncode, 2)

    def test_missing_caelestia_fails_before_changes(self) -> None:
        self.require_user()
        (self.config/'hypr/hyprland.lua').unlink()
        self.assertNotEqual(self.run_script('--no-apply').returncode, 0)
        self.assertFalse((self.config/'caelestia').exists())

    def test_clean_deployment_and_executable_hook(self) -> None:
        self.require_user()
        result = self.run_script('--no-apply')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.config/'caelestia/hypr-vars.lua').read_bytes(),
                         (ROOT/'home/caelestia/hypr-vars.lua').read_bytes())
        hook = self.home/'.local/bin/normie-wallpaper.fish'
        self.assertTrue(os.access(hook, os.X_OK))
        self.assertTrue((self.home/'Pictures/Wallpapers/momiji-dots-normie/arch-horizon.png').is_file())
        self.assertFalse((self.home/'.local/state/momiji-dots-normie/backups').exists())

    def test_idempotent_second_deploy_creates_no_backup(self) -> None:
        self.require_user()
        first = self.run_script('--no-apply')
        second = self.run_script('--no-apply')
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertNotIn('Backup:', second.stdout)

    def test_existing_file_is_backed_up(self) -> None:
        self.require_user()
        target = self.config/'caelestia/hypr-vars.lua'
        target.parent.mkdir(parents=True)
        target.write_text('old user configuration\n')
        result = self.run_script('--no-apply')
        self.assertEqual(result.returncode, 0, result.stderr)
        backups = list((self.home/'.local/state/momiji-dots-normie/backups').rglob('hypr-vars.lua'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), 'old user configuration\n')
        self.assertNotEqual(target.read_text(), 'old user configuration\n')

    def test_symlink_replacement_preserves_former_target(self) -> None:
        self.require_user()
        outside = Path(self.temp.name)/'original config.lua'
        outside.write_text('do not modify this\n')
        target = self.config/'caelestia/hypr-vars.lua'
        target.parent.mkdir(parents=True)
        target.symlink_to(outside)
        result = self.run_script('--no-apply')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(target.is_symlink())
        self.assertEqual(outside.read_text(), 'do not modify this\n')
        backups = list((self.home/'.local/state/momiji-dots-normie/backups').rglob('hypr-vars.lua'))
        self.assertEqual(len(backups), 1)
        self.assertTrue(backups[0].is_symlink())

    def test_unrelated_wallpapers_remain_outside_pool(self) -> None:
        self.require_user()
        other = self.home/'Pictures/Wallpapers/existing-picture.png'
        other.parent.mkdir(parents=True)
        other.write_bytes(b'untouched')
        result = self.run_script('--no-apply')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(other.read_bytes(), b'untouched')
        pool = self.home/'Pictures/Wallpapers/momiji-dots-normie'
        self.assertEqual([p.name for p in pool.iterdir()], ['arch-horizon.png'])

    def test_xdg_paths_are_respected(self) -> None:
        self.require_user()
        custom = self.home/'custom config'
        (custom/'hypr').mkdir(parents=True)
        (custom/'hypr/hyprland.lua').write_text('-- fixture\n')
        self.env['XDG_CONFIG_HOME'] = str(custom)
        self.env['XDG_STATE_HOME'] = str(self.home/'custom state')
        result = self.run_script('--no-apply')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((custom/'fastfetch/config.jsonc').is_file())
        self.assertFalse((self.config/'fastfetch').exists())

    def test_directory_target_is_not_deleted(self) -> None:
        self.require_user()
        target = self.config/'caelestia/hypr-vars.lua'
        target.mkdir(parents=True)
        sentinel = target/'sentinel'
        sentinel.write_text('keep')
        result = self.run_script('--no-apply')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(sentinel.read_text(), 'keep')

if __name__ == '__main__':
    unittest.main()
