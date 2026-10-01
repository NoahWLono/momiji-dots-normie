#!/usr/bin/env fish
# Publish this clean snapshot without altering your installed desktop.
set -l root (path resolve (path dirname (status filename)))
bash "$root/scripts/publish-github.sh" $argv
exit $status
