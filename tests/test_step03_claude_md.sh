#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
source "$REPO_DIR/lib/common.sh"
REAL_REPO="$REPO_DIR"
BEGIN='<!-- setup-claude:begin -->'; END='<!-- setup-claude:end -->'
# shellcheck disable=SC1090
step() { ( source "$REAL_REPO/steps/03-claude-md.sh"; REPO_DIR="${FAKE_REPO:-$REAL_REPO}" step_run ) 2>&1; }
baks() { find "$HOME/.claude" -name 'CLAUDE.md.bak.*' | wc -l; }
nblocks() { grep -cF "$BEGIN" "$HOME/.claude/CLAUDE.md"; }

# config content
cfg="$(cat "$REAL_REPO/config/CLAUDE.md")"
assert_contains "$cfg" "Search order" "config has the one graphify-vs-qmd rule"
assert_contains "$cfg" "graphify" "config mentions graphify in the search order"
assert_contains "$cfg" "qmd" "config mentions qmd in the search order"
assert_eq 0 "$(printf '%s' "$cfg" | grep -c 'Available tools')" "config does not repeat the qmd command list (qmd skill covers it)"
assert_eq 0 "$(printf '%s' "$cfg" | grep -c 'GRAPH_REPORT')" "config does not repeat graphify's own rules"
assert_eq 0 "$(printf '%s' "$cfg" | grep -c 'use the installed graphify skill')" "config does not repeat the /graphify line (harness handles slash skills)"
assert_eq 1 "$([ "$(printf '%s\n' "$cfg" | wc -l)" -lt 25 ] && echo 1 || echo 0)" "config block stays short"
assert_contains "$cfg" "Code Review Standards" "config has code review standards"
assert_eq 0 "$(printf '%s' "$cfg" | grep -c 'How to Respond')" "config omits How to Respond"
assert_eq 0 "$(printf '%s' "$cfg" | grep -c '/home/')" "config has no personal paths"

# fresh install, ~/.claude missing
make_sandbox; rm -rf "$HOME/.claude"
out=$(step); assert_eq 0 $? "fresh ok"
assert_eq 1 "$(nblocks)" "one block on fresh install"
sum1=$(cksum < "$HOME/.claude/CLAUDE.md")
out=$(step); assert_contains "$out" "already current" "re-run is a no-op"
assert_eq "$sum1" "$(cksum < "$HOME/.claude/CLAUDE.md")" "re-run leaves file unchanged"
assert_eq 0 "$(baks)" "no backups on fresh/re-run"
assert_eq 1 "$(nblocks)" "still one block after re-run"

# existing file without markers
make_sandbox; echo "my own rule" > "$HOME/.claude/CLAUDE.md"
out=$(step); assert_eq 0 $? "unmarked ok"
assert_eq 1 "$(baks)" "unmarked file is backed up"
assert_contains "$(cat "$HOME/.claude/CLAUDE.md")" "my own rule" "existing rule kept"
assert_eq 1 "$(nblocks)" "block appended"
assert_contains "$out" "warning:" "duplicate-rules warning shown"

# markers with text around; block body replaced
make_sandbox; FAKE_REPO="$SANDBOX/fake"; mkdir -p "$FAKE_REPO/config"
ln -s "$REAL_REPO/lib" "$FAKE_REPO/lib"
printf 'new body\n' > "$FAKE_REPO/config/CLAUDE.md"
printf 'before\n%s\nold body\n%s\nafter\n' "$BEGIN" "$END" > "$HOME/.claude/CLAUDE.md"
out=$(FAKE_REPO="$FAKE_REPO" step); assert_eq 0 $? "marked ok"
res="$(cat "$HOME/.claude/CLAUDE.md")"
assert_eq "before
$BEGIN
new body
$END
after" "$res" "only the block was replaced"
assert_eq 1 "$(baks)" "changed file is backed up"
FAKE_REPO="$FAKE_REPO" step >/dev/null
assert_eq 1 "$(baks)" "no second backup when unchanged"
unset FAKE_REPO

# mode and symlink preserved
make_sandbox; echo "mine" > "$HOME/.claude/CLAUDE.md"; chmod 600 "$HOME/.claude/CLAUDE.md"; step >/dev/null
assert_eq 600 "$(stat -c %a "$HOME/.claude/CLAUDE.md")" "CLAUDE.md keeps mode 600"
make_sandbox; echo "mine" > "$HOME/real.md"; ln -s "$HOME/real.md" "$HOME/.claude/CLAUDE.md"; step >/dev/null
assert_eq 1 "$([ -L "$HOME/.claude/CLAUDE.md" ] && echo 1 || echo 0)" "CLAUDE.md symlink stays a symlink"
assert_contains "$(cat "$HOME/real.md")" "setup-claude:begin" "symlink target got the block"

# begin marker without end marker: refuse, touch nothing
make_sandbox; printf 'mine1\n%s\nedited body\nmy later rule\n' "$BEGIN" > "$HOME/.claude/CLAUDE.md"; before=$(cksum < "$HOME/.claude/CLAUDE.md")
out=$(step); rc=$?
assert_eq 1 "$rc" "unmatched begin marker is FAILED"
assert_contains "$out" "reason: unmatched" "reason names the unmatched marker"
assert_eq "$before" "$(cksum < "$HOME/.claude/CLAUDE.md")" "unmatched marker: file untouched"
assert_eq 0 "$(baks)" "unmatched marker: no backup churn"

# dry run
make_sandbox; out=$(DRY_RUN=1 step); assert_eq 0 $? "dry-run ok"
assert_eq 0 "$([ -e "$HOME/.claude/CLAUDE.md" ] && echo 1 || echo 0)" "dry-run writes nothing"
finish
