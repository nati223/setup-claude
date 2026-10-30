#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
make_sandbox
source "$REPO_DIR/lib/common.sh"

have bash; assert_eq 0 $? "have finds bash"
have nonexistent-cmd-xyz; assert_eq 1 $? "have misses unknown cmd"

ensure_path; ensure_path
count=$(printf '%s' "$PATH" | tr ':' '\n' | grep -cxF "$HOME/.local/bin")
assert_eq 1 "$count" "ensure_path adds .local/bin exactly once"

echo data > "$HOME/f.txt"
backup_file "$HOME/f.txt"
bak=$(ls "$HOME"/f.txt.bak.* 2>/dev/null | head -1)
assert_eq data "$(cat "$bak" 2>/dev/null)" "backup_file copies content"
backup_file "$HOME/missing.txt"; assert_eq 0 $? "backup_file on missing file returns 0"
assert_eq 0 "$(ls "$HOME"/missing.txt.bak.* 2>/dev/null | wc -l)" "no backup created for missing file"

assert_eq hi "$(run echo hi)" "run executes"
out=$(DRY_RUN=1 run touch "$SANDBOX/x")
assert_contains "$out" "[dry-run]" "dry-run prints marker"
assert_eq 0 "$([ -e "$SANDBOX/x" ] && echo 1 || echo 0)" "dry-run does not execute"
log hello | grep -q '^\[setup\] hello$'; assert_eq 0 $? "log format"
finish
