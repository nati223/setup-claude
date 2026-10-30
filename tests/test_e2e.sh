#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
inst() { bash "$REPO_DIR/install.sh" "$@" 2>&1; }
baks() { find "$HOME" -name '*.bak.*' | wc -l; }
setup() {
  make_sandbox; make_min_path
  fake_cmd claude 'echo 9.9.9 \(Claude Code\)'; fake_cmd uv; fake_cmd graphify; fake_cmd qmd 'echo 2.8.3'
  fake_cmd node 'echo v22.1.0'; fake_cmd npm; fake_cmd pip
}

setup; out=$(inst); rc=$?
assert_eq 0 "$rc" "e2e: exit 0"
for s in 01-claude 02-plugins 03-graphify 04-qmd-cli 05-style 06-settings 07-claude-md; do
  assert_contains "$out" "OK       $s" "e2e: $s OK"
done
assert_contains "$out" "SKIPPED  90-headroom" "e2e: headroom skipped"
assert_eq "sonnet opus" "$(python3 -c "import json,os;d=json.load(open(os.path.expanduser('~/.claude/settings.json')));print(d['model'],d['advisorModel'])")" "e2e: settings keys"
assert_eq 1 "$([ -f "$HOME/.claude/output-styles/concise-custom.md" ] && echo 1 || echo 0)" "e2e: style installed"
assert_contains "$(cat "$HOME/.claude/CLAUDE.md")" "setup-claude:begin" "e2e: CLAUDE.md block"
out=$(inst); rc=$?
assert_eq 0 "$rc" "e2e: second run exit 0"
assert_eq 0 "$(baks)" "e2e: re-run creates no backups"
assert_eq 1 "$(grep -c 'setup-claude:begin' "$HOME/.claude/CLAUDE.md")" "e2e: still one CLAUDE.md block"

setup; rm -rf "$HOME/.claude"
out=$(inst --dry-run); rc=$?
assert_eq 0 "$rc" "e2e dry-run: exit 0"
assert_eq 0 "$([ -e "$HOME/.claude" ] && echo 1 || echo 0)" "e2e dry-run: ~/.claude not created"
assert_eq 0 "$([ -e "$HOME/.bashrc" ] && echo 1 || echo 0)" "e2e dry-run: no .bashrc"

# README facts
readme="$(cat "$REPO_DIR/README.md" 2>/dev/null)"
assert_contains "$readme" "source ~/.bashrc" "README: source bashrc"
assert_contains "$readme" "--with-headroom" "README: headroom flag"
assert_contains "$readme" "PDF" "README: qmd binary-file limit"
assert_contains "$readme" "MIT" "README: license"
finish
