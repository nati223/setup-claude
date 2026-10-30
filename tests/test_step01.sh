#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ORIG_PATH="/usr/bin:/bin"; export PATH="$ORIG_PATH"   # hide the real claude
source "$REPO_DIR/lib/common.sh"

step() { ( source "$REPO_DIR/steps/01-claude.sh"; step_run ) 2>&1; }
fake_installer() { # file creating a fake claude
  cat > "$1" <<'INST'
mkdir -p "$HOME/.local/bin"
printf '#!/bin/sh\necho "9.9.9 (Claude Code)"\n' > "$HOME/.local/bin/claude"
chmod +x "$HOME/.local/bin/claude"
INST
}
count_path_lines() { grep -c 'export PATH=.*\.local/bin' "$HOME/.bashrc" 2>/dev/null; }

# fresh install, HOME with a space, no .bashrc yet
make_sandbox; fake_installer "$SANDBOX/inst.sh"
export CLAUDE_INSTALL_URL="file://$SANDBOX/inst.sh"
out=$(step); rc=$?
assert_eq 0 "$rc" "install ok"
assert_contains "$out" "reason: installed 9.9.9" "reason names version"
assert_contains "$out" "source ~/.bashrc" "tells user to source bashrc"
assert_eq 1 "$(count_path_lines)" "PATH line added once (bashrc created)"
out=$(step); rc=$?
assert_eq 0 "$rc" "second run ok"
assert_contains "$out" "already installed" "second run detects install"
assert_eq 1 "$(count_path_lines)" "PATH line not duplicated on re-run"

# download fails
make_sandbox
export CLAUDE_INSTALL_URL="file:///nonexistent/inst.sh"
out=$(step); rc=$?
assert_eq 1 "$rc" "download failure is FAILED"
assert_contains "$out" "reason:" "failure has reason"
assert_eq 0 "$([ -e "$HOME/.bashrc" ] && echo 1 || echo 0)" "bashrc untouched on failure"

# installer runs but claude does not appear
make_sandbox; echo 'true' > "$SANDBOX/noop.sh"
export CLAUDE_INSTALL_URL="file://$SANDBOX/noop.sh"
out=$(step); rc=$?
assert_eq 1 "$rc" "missing claude after install is FAILED"
assert_contains "$out" "reason:" "missing-binary has reason"

# dry run
make_sandbox; fake_installer "$SANDBOX/inst.sh"
export CLAUDE_INSTALL_URL="file://$SANDBOX/inst.sh"
out=$(DRY_RUN=1 step); rc=$?
assert_eq 0 "$rc" "dry-run ok"
assert_eq 0 "$([ -e "$HOME/.local/bin/claude" ] && echo 1 || echo 0)" "dry-run installs nothing"
assert_eq 0 "$([ -e "$HOME/.bashrc" ] && echo 1 || echo 0)" "dry-run writes no bashrc"
finish
