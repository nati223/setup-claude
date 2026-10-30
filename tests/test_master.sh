#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
make_sandbox
export STEPS_DIR="$SANDBOX/steps"; mkdir -p "$STEPS_DIR"
printf 'step_run() { log "reason: fine-a"; return 0; }\n' > "$STEPS_DIR/01-a.sh"
printf 'step_run() { log "reason: boom"; return 1; }\n' > "$STEPS_DIR/02-b.sh"
printf 'step_run() { log "reason: nothing to do"; return 3; }\n' > "$STEPS_DIR/03-c.sh"
printf 'step_run() { echo "DRY=$DRY_RUN"; return 0; }\n' > "$STEPS_DIR/04-d.sh"
printf 'step_run() { exit 5; }\n' > "$STEPS_DIR/05-e.sh"
printf 'step_run() { echo "WH=$WITH_HEADROOM"; return 0; }\n' > "$STEPS_DIR/90-headroom.sh"

inst() { bash "$REPO_DIR/install.sh" "$@" 2>&1; }

out=$(inst); rc=$?
assert_eq 1 "$rc" "exit 1 when a step failed"
assert_contains "$out" "FAILED   02-b  boom" "failed step shown with reason"
assert_contains "$out" "OK       04-d" "later step still ran after failure"
assert_contains "$out" "SKIPPED  03-c  nothing to do" "skipped step shown"
assert_contains "$out" "FAILED   05-e" "step calling exit is FAILED"
assert_contains "$out" "SKIPPED  90-headroom" "headroom skipped by default"

out=$(inst --only 01); rc=$?
assert_eq 0 "$rc" "--only number: exit 0"
assert_contains "$out" "OK       01-a" "--only number runs it"
assert_contains "$out" "SKIPPED  02-b" "--only number skips others"
out=$(inst --only a --only d)
assert_contains "$out" "OK       01-a" "--only name a"
assert_contains "$out" "OK       04-d" "--only repeats"
assert_contains "$out" "SKIPPED  02-b" "--only others skipped"

out=$(inst --skip 02 --skip d --skip 05)
assert_contains "$out" "SKIPPED  02-b" "--skip by number"
assert_contains "$out" "SKIPPED  04-d" "--skip by name"
assert_eq 0 "$(printf '%s' "$out" | grep -c '^FAILED')" "no failed steps after skips"

out=$(inst --only d --dry-run)
assert_contains "$out" "DRY=1" "dry-run flag reaches steps"
assert_contains "$out" "DRY      04-d" "dry-run status"

out=$(inst --only headroom --with-headroom)
assert_contains "$out" "WH=1" "--with-headroom reaches step"
assert_contains "$out" "OK       90-headroom" "headroom runs with flag"

out=$(inst --bogus); rc=$?
assert_eq 2 "$rc" "unknown flag exits 2"
assert_contains "$out" "Usage" "usage printed"
finish
