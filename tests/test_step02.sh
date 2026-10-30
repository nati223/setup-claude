#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
source "$REPO_DIR/lib/common.sh"

make_fake_claude() { # writes $SANDBOX/fakebin/claude; behaviour via env FAKE_*
  mkdir -p "$SANDBOX/fakebin"
  cat > "$SANDBOX/fakebin/claude" <<'FAKE'
#!/usr/bin/env bash
echo "$*" >> "$FAKE_LOG"
case "$1 $2 $3" in
  "plugin marketplace list") printf '%s\n' ${FAKE_MARKETS-claude-plugins-official}; exit 0 ;;
  "plugin marketplace add") [ "$4" = "${FAKE_FAIL_ADD:-}" ] && { echo "add failed" >&2; exit 1; }; exit 0 ;;
esac
case "$1 $2" in
  "plugin list") for i in ${FAKE_INSTALLED:-}; do echo "  ❯ $i"; echo "    Status: enabled"; done; exit 0 ;;
  "plugin install") [ "$3" = "${FAKE_FAIL_ID:-}" ] && { echo "install failed" >&2; exit 1; }; exit 0 ;;
esac
exit 0
FAKE
  chmod +x "$SANDBOX/fakebin/claude"
}
# shellcheck disable=SC1090
step() { ( source "$REPO_DIR/steps/02-plugins.sh"; step_run ) 2>&1; }
n() { grep -c "$1" "$FAKE_LOG"; }
setup() { make_sandbox; make_fake_claude; export FAKE_LOG="$SANDBOX/calls.log" CLAUDE_BIN="$SANDBOX/fakebin/claude"; : > "$FAKE_LOG"; unset FAKE_FAIL_ID FAKE_FAIL_ADD FAKE_INSTALLED; }

setup; out=$(step); rc=$?
assert_eq 0 "$rc" "all succeed: rc 0"
assert_eq 3 "$(n '^plugin marketplace add')" "3 marketplace adds (official already known)"
assert_eq 4 "$(n '^plugin install')" "4 installs"
assert_contains "$(cat "$FAKE_LOG")" "plugin marketplace add tobi/qmd" "qmd marketplace repo"
assert_contains "$(cat "$FAKE_LOG")" "plugin install claude-handoff@claude-handoff" "handoff id"
assert_contains "$(cat "$FAKE_LOG")" "plugin install andrej-karpathy-skills@karpathy-skills" "karpathy id"
assert_contains "$(cat "$FAKE_LOG")" "plugin install superpowers@claude-plugins-official" "superpowers id"

setup; export FAKE_FAIL_ID="qmd@qmd"; out=$(step); rc=$?
assert_eq 1 "$rc" "one install fails: rc 1"
assert_contains "$out" "reason:" "reason line present"
assert_contains "$(printf '%s' "$out" | grep 'reason:')" "qmd@qmd" "reason names failed plugin"
assert_eq 4 "$(n '^plugin install')" "other installs still attempted"

setup; export FAKE_FAIL_ADD="tobi/qmd"; out=$(step); rc=$?
assert_eq 1 "$rc" "marketplace add fails: rc 1"
assert_eq 3 "$(n '^plugin install')" "no install attempted for plugin whose marketplace failed"

setup; export FAKE_INSTALLED="andrej-karpathy-skills@karpathy-skills"; out=$(step); rc=$?
assert_eq 0 "$rc" "already-installed plugin: rc 0"
assert_eq 3 "$(n '^plugin install')" "already-installed plugin not reinstalled"
assert_contains "$out" "already installed" "already-installed logged"

setup; export FAKE_MARKETS=""; out=$(step)
assert_contains "$(cat "$FAKE_LOG")" "plugin marketplace add anthropics/claude-plugins-official" "official marketplace added when unknown"

setup; export CLAUDE_BIN="$SANDBOX/nope"; out=$(step); rc=$?
assert_eq 1 "$rc" "missing claude: rc 1"
assert_contains "$out" "claude not found" "missing claude reason"

setup; NET_TIMEOUT=1; export NET_TIMEOUT
sed -i 's|^  "plugin install")|  "plugin install") [ "$3" = "${FAKE_HANG_ID:-}" ] \&\& exec sleep 5;|' "$SANDBOX/fakebin/claude"
export FAKE_HANG_ID="qmd@qmd"; start=$(date +%s); out=$(step); rc=$?; took=$(( $(date +%s) - start ))
assert_eq 1 "$rc" "hanging install is FAILED, not a hang"
assert_contains "$(printf '%s' "$out" | grep 'reason:')" "qmd@qmd" "hung plugin named in reason"
assert_eq 1 "$([ "$took" -lt 4 ] && echo 1 || echo 0)" "hang cut off by NET_TIMEOUT"
unset FAKE_HANG_ID NET_TIMEOUT

setup; out=$(DRY_RUN=1 step); rc=$?
assert_eq 0 "$rc" "dry-run rc 0"
assert_eq 0 "$(n '^plugin install')" "dry-run makes no installs"
assert_eq 0 "$(n '^plugin marketplace add')" "dry-run adds no marketplaces"
finish
