#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
inst() { bash "$REPO_DIR/install.sh" "$@" 2>&1; }
baks() { find "$HOME" -name '*.bak.*' | wc -l; }
fake_graphify() { # mimics real graphify: creates/appends a '# graphify' block in CLAUDE.md unless it already mentions graphify
  fake_cmd graphify 'f="$HOME/.claude/CLAUDE.md"; if [ ! -f "$f" ]; then printf "# graphify\nrules\n" > "$f"; elif ! grep -q graphify "$f"; then printf "# graphify\nrules\n" >> "$f"; fi'
}
setup() {
  make_sandbox; make_min_path
  fake_cmd claude 'echo 9.9.9 \(Claude Code\)'; fake_cmd uv; fake_graphify; fake_cmd qmd 'echo 2.8.3'
  fake_cmd node 'echo v22.1.0'; fake_cmd npm; fake_cmd pip
}

setup; out=$(inst); rc=$?
assert_eq 0 "$rc" "e2e: exit 0"
for s in 01-claude 02-plugins 07-graphify 04-qmd-cli 05-style 06-settings 03-claude-md; do
  assert_contains "$out" "OK       $s" "e2e: $s OK"
done
assert_contains "$out" "SKIPPED  90-headroom" "e2e: headroom skipped"
assert_eq "sonnet opus" "$(python3 -c "import json,os;d=json.load(open(os.path.expanduser('~/.claude/settings.json')));print(d['model'],d['advisorModel'])")" "e2e: settings keys"
assert_eq 1 "$([ -f "$HOME/.claude/output-styles/concise-custom.md" ] && echo 1 || echo 0)" "e2e: style installed"
assert_contains "$(cat "$HOME/.claude/CLAUDE.md")" "setup-claude:begin" "e2e: CLAUDE.md block"
assert_eq 0 "$(printf '%s' "$out" | grep -c 'warning:')" "e2e: no duplicate-rules warning on a fresh install"
assert_eq 0 "$(find "$HOME/.claude" -name 'CLAUDE.md.bak.*' | wc -l)" "e2e: fresh install does not back up a file it just made"
out=$(inst); rc=$?
assert_eq 0 "$rc" "e2e: second run exit 0"
out=$(inst); before=$(baks); out=$(inst)
assert_eq "$before" "$(baks)" "e2e: runs converge: no new backups once settled"
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
