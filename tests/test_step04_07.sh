#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
source "$REPO_DIR/lib/common.sh"
# shellcheck disable=SC1090
step() { ( source "$REPO_DIR/steps/$1.sh"; step_run ) 2>&1; }
n() { grep -c "$1" "$FAKE_LOG"; }
setup() { make_sandbox; make_min_path; unset UV_INSTALL_URL; }

# --- step 07 (graphify)
setup; fake_cmd uv; fake_cmd graphify
out=$(step 07-graphify); rc=$?
assert_eq 0 "$rc" "07: uv present: ok"
assert_eq 0 "$(n '^pip')" "07: uv present: no pip"
assert_contains "$(cat "$FAKE_LOG")" "graphify install --platform claude" "07: runs graphify install"
assert_eq 0 "$(n '^uv tool install')" "07: graphify present: no uv tool install"

setup; fake_cmd uv; out=$(step 07-graphify); rc=$?
assert_contains "$(cat "$FAKE_LOG")" "uv tool install graphifyy" "07: installs graphifyy (two y)"

setup; fake_cmd pip "printf '#!/bin/bash\necho uv >> \"\$FAKE_LOG\"\n' > \"$SANDBOX/fake/uv\"; chmod +x \"$SANDBOX/fake/uv\""
fake_cmd graphify; out=$(step 07-graphify); rc=$?
assert_eq 0 "$rc" "07: uv via pip ok"
assert_contains "$(cat "$FAKE_LOG")" "pip install --user -q uv" "07: pip --user uv"

setup; fake_cmd pip "exit 1"; fake_cmd graphify
printf 'printf "#!/bin/bash\\n" > "%s/fake/uv"; chmod +x "%s/fake/uv"\n' "$SANDBOX" "$SANDBOX" > "$SANDBOX/uvinst.sh"
export UV_INSTALL_URL="file://$SANDBOX/uvinst.sh"
out=$(step 07-graphify); rc=$?
assert_eq 0 "$rc" "07: pip fails, astral installer used"

setup; fake_cmd pip "exit 1"; export UV_INSTALL_URL="file:///nonexistent"
out=$(step 07-graphify); rc=$?
assert_eq 1 "$rc" "07: all uv routes fail: FAILED"
assert_contains "$out" "reason: could not install uv" "07: reason names uv"

setup; out=$(DRY_RUN=1 step 07-graphify); rc=$?
assert_eq 0 "$rc" "07: dry-run ok even with nothing installed"

# --- step 04
setup; out=$(step 04-qmd-cli); rc=$?
assert_eq 1 "$rc" "04: no npm/bun: FAILED"
assert_contains "$out" "need npm" "04: reason says need npm"

setup; fake_cmd node 'echo v22.1.0'; fake_cmd npm "printf '#!/bin/bash\necho 2.8.3\n' > \"$SANDBOX/fake/qmd\"; chmod +x \"$SANDBOX/fake/qmd\""
out=$(step 04-qmd-cli); rc=$?
assert_eq 0 "$rc" "04: npm install ok"
assert_contains "$(cat "$FAKE_LOG")" "@tobilu/qmd" "04: installs @tobilu/qmd"

setup; fake_cmd node 'echo v20.5.0'; fake_cmd npm
out=$(step 04-qmd-cli); rc=$?
assert_eq 1 "$rc" "04: old node: FAILED"
assert_contains "$out" "v20" "04: reason shows node version"
assert_eq 0 "$(n '^npm')" "04: old node: npm not run"

setup; fake_cmd qmd 'echo 2.8.3'; fake_cmd npm
out=$(step 04-qmd-cli); rc=$?
assert_eq 0 "$rc" "04: qmd present ok"
assert_eq 0 "$(n '^npm')" "04: qmd present: no npm"

setup; fake_cmd node 'echo v22.1.0'; fake_cmd npm
out=$(step 04-qmd-cli); rc=$?
assert_eq 1 "$rc" "04: npm ran but qmd missing: FAILED"

setup; fake_cmd node 'echo v22.1.0'; fake_cmd npm; out=$(DRY_RUN=1 step 04-qmd-cli); rc=$?
assert_eq 0 "$rc" "04: dry-run ok"
assert_eq 0 "$(n '^npm')" "04: dry-run runs no npm"
finish
