from __future__ import annotations
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
REAL_GIT = shutil.which('git')

# Test doubles intercept all remote operations; ordinary local Git is real.
FAKE = r"""#!/usr/bin/env bash
set -eu
name=${0##*/}
{
    printf '%s\0' "$name" "$@"
    printf '\0'
} >> "$FAKE_STATE/calls"
if [[ "$name" == git ]]; then
    for arg in "$@"; do
        if [[ "$arg" == push ]]; then
            [[ ${FAKE_PUSH_FAIL:-0} != 1 ]] || exit 1
            root=$2
            "$REAL_GIT" -C "$root" rev-parse HEAD > "$FAKE_STATE/sha"
            exit 0
        fi
    done
    exec "$REAL_GIT" "$@"
fi
if [[ "$1 $2" == 'auth status' ]]; then exit 0; fi
if [[ "$1 $2" == 'repo create' ]]; then touch "$FAKE_STATE/exists"; exit 0; fi
if [[ "$1 $2" == 'api user' ]]; then
    if [[ "${!#}" == .login ]]; then echo "${FAKE_LOGIN:-NoahWLono}"; else echo 288722424; fi
    exit 0
fi
if [[ "$1" == api ]]; then
    case "$2" in
        */branches|*/git/ref/heads/main)
            if [[ -n ${FAKE_BRANCH_SHA:-} ]]; then echo "$FAKE_BRANCH_SHA";
            elif [[ -f "$FAKE_STATE/sha" ]]; then cat "$FAKE_STATE/sha";
            else printf '\n'; fi ;;
        */tags) printf '\n' ;;
        *) [[ -f "$FAKE_STATE/exists" ]] || exit 1
           printf 'NoahWLono\tfalse\tfalse\n' ;;
    esac
    exit 0
fi
echo 'Unexpected fake tool call.' >&2
exit 1
"""

@unittest.skipUnless(REAL_GIT, 'Git required for local publisher integration tests')
class PublisherTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory(prefix='normie-publish-test-')
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.repo = self.base/'release'
        shutil.copytree(ROOT, self.repo, ignore=shutil.ignore_patterns('.git', '__pycache__'))
        self.bin = self.base/'bin'; self.bin.mkdir()
        for name in ('git', 'gh'):
            tool = self.bin/name; tool.write_text(FAKE); tool.chmod(0o755)
        self.state = self.base/'remote'; self.state.mkdir()
        self.env = dict(os.environ, PATH=str(self.bin)+os.pathsep+os.environ['PATH'],
                        REAL_GIT=REAL_GIT, FAKE_STATE=str(self.state),
                        GIT_CONFIG_GLOBAL='/dev/null', GIT_CONFIG_NOSYSTEM='1')
        self.env.pop('FAKE_LOGIN', None)
        self.env.pop('FAKE_PUSH_FAIL', None)
        self.env.pop('FAKE_BRANCH_SHA', None)

    def run_publish(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(['bash', str(self.repo/'scripts/publish-github.sh')],
                              env=self.env, capture_output=True, text=True, timeout=30)

    def state_data(self) -> dict:
        calls_file = self.state/'calls'
        calls = []
        if calls_file.exists():
            for entry in calls_file.read_bytes().split(b'\0\0'):
                if entry:
                    calls.append([value.decode() for value in entry.split(b'\0')])
        sha_file = self.state/'sha'
        return {'exists': (self.state/'exists').exists(), 'calls': calls,
                'sha': sha_file.read_text().strip() if sha_file.exists() else ''}

    def test_creates_and_verifies_expected_repo_only(self) -> None:
        result = self.run_publish()
        self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
        data = self.state_data()
        creates = [x for x in data['calls'] if x[:3] == ['gh', 'repo', 'create']]
        pushes = [x for x in data['calls'] if x[0] == 'git' and 'push' in x]
        self.assertEqual(len(creates), 1)
        self.assertEqual(creates[0][3], 'NoahWLono/momiji-dots-normie')
        self.assertIn('--public', creates[0])
        self.assertEqual(len(pushes), 1)
        self.assertNotIn('--force', pushes[0])
        self.assertIn(data['sha'], result.stdout)

    def test_wrong_account_refused_before_local_history(self) -> None:
        self.env['FAKE_LOGIN'] = 'DifferentAccount'
        result = self.run_publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.repo/'.git').exists())
        self.assertNotIn('push', ' '.join(map(str, self.state_data().get('calls', []))))

    def test_other_remote_history_refused(self) -> None:
        (self.state/'exists').touch()
        self.env['FAKE_BRANCH_SHA'] = '1'*40
        result = self.run_publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('different history', result.stderr)
        self.assertFalse(any(x[0] == 'git' and 'push' in x for x in self.state_data()['calls']))

    def test_modified_release_rejected_before_auth(self) -> None:
        (self.repo/'README.md').write_text('modified\n')
        result = self.run_publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.repo/'.git').exists())
        self.assertEqual(self.state_data().get('calls', []), [])

    def test_extra_file_rejected_before_auth(self) -> None:
        (self.repo/'personal-notes.txt').write_text('do not publish\n')
        result = self.run_publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Release file set changed', result.stderr)
        self.assertEqual(self.state_data().get('calls', []), [])

    def test_matching_published_commit_is_idempotent(self) -> None:
        first = self.run_publish()
        self.assertEqual(first.returncode, 0, first.stdout+first.stderr)
        second = self.run_publish()
        self.assertEqual(second.returncode, 0, second.stdout+second.stderr)
        self.assertIn('Already published', second.stdout)
        pushes = [x for x in self.state_data()['calls'] if x[0] == 'git' and 'push' in x]
        self.assertEqual(len(pushes), 1)

    def test_failed_push_can_resume_without_force(self) -> None:
        self.env['FAKE_PUSH_FAIL'] = '1'
        failed = self.run_publish()
        self.assertNotEqual(failed.returncode, 0)
        self.assertIn('publication did not complete', failed.stderr)
        self.env.pop('FAKE_PUSH_FAIL')
        resumed = self.run_publish()
        self.assertEqual(resumed.returncode, 0, resumed.stdout+resumed.stderr)
        creates = [x for x in self.state_data()['calls'] if x[:3] == ['gh', 'repo', 'create']]
        self.assertEqual(len(creates), 1)

if __name__ == '__main__':
    unittest.main()
