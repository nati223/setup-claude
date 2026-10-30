#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
source "$REPO_DIR/lib/common.sh"
# shellcheck disable=SC1090
step() { ( source "$REPO_DIR/steps/90-headroom.sh"; step_run ) 2>&1; }
n() { grep -c "$1" "$FAKE_LOG"; }
setup() { make_sandbox; make_min_path; unset CLAUDE_BIN; fake_cmd uv; fake_cmd claude; }

setup; out=$(step); rc=$?
assert_eq 0 "$rc" "90: ok"
log_all="$(cat "$FAKE_LOG")"
assert_contains "$log_all" 'uv tool install --python 3.13 headroom-ai[all]' "90: installs headroom CLI via uv"
assert_contains "$log_all" "claude plugin marketplace add chopratejas/headroom" "90: adds marketplace"
assert_contains "$log_all" "claude plugin install headroom@headroom-marketplace" "90: installs plugin"
assert_eq 0 "$(n 'wrap')" "90: never runs headroom wrap"
assert_contains "$out" "headroom wrap claude" "90: tells owner how to enable by hand"

setup; fake_cmd headroom; out=$(step)
assert_eq 0 "$(n '^uv tool install')" "90: CLI present: no uv tool install"

setup; fake_cmd claude 'case "$2 $3" in "install headroom@headroom-marketplace") exit 1;; esac; exit 0'
out=$(step); rc=$?
assert_eq 1 "$rc" "90: plugin install fails: FAILED"
assert_contains "$out" "reason:" "90: failure has reason"

setup; out=$(DRY_RUN=1 step); rc=$?
assert_eq 0 "$rc" "90: dry-run ok"
assert_eq 0 "$(n '^uv tool install')" "90: dry-run installs nothing"
assert_eq 0 "$(n 'plugin install')" "90: dry-run installs no plugin"

# master with the real steps dir: headroom stays off without the flag
out=$(PATH="$ORIG_PATH" bash "$REPO_DIR/install.sh" --only headroom --dry-run 2>&1)
assert_contains "$out" "SKIPPED  90-headroom  needs --with-headroom" "master skips headroom by default"
finish
