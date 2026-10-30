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

# backup dedupe: unchanged file is not backed up twice; a changed one is, and no backup is overwritten
echo v1 > "$HOME/g.txt"; backup_file "$HOME/g.txt"; backup_file "$HOME/g.txt"
assert_eq 1 "$(find "$HOME" -name 'g.txt.bak.*' | wc -l)" "backup_file skips identical content"
echo v2 > "$HOME/g.txt"; backup_file "$HOME/g.txt"; echo v3 > "$HOME/g.txt"; backup_file "$HOME/g.txt"
assert_eq 3 "$(find "$HOME" -name 'g.txt.bak.*' | wc -l)" "changed content gets new backups, none overwritten"

# run_net: bounded by NET_TIMEOUT
start=$(date +%s); NET_TIMEOUT=1 run_net sleep 5; rc=$?; took=$(( $(date +%s) - start ))
assert_eq 124 "$rc" "run_net times out with 124"
assert_eq 1 "$([ "$took" -lt 4 ] && echo 1 || echo 0)" "run_net returns promptly"
out=$(DRY_RUN=1 run_net echo hi); assert_contains "$out" "[dry-run]" "run_net honours dry-run"
finish
