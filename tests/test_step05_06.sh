#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
source "$REPO_DIR/lib/common.sh"
MERGE="$REPO_DIR/lib/merge_settings.py"
STYLE_SRC="$REPO_DIR/config/output-styles/concise-custom.md"
# shellcheck disable=SC1090
step() { ( source "$REPO_DIR/steps/$1.sh"; step_run ) 2>&1; }
baks() { find "$HOME/.claude" -name "$1.bak.*" | wc -l; }
val() { python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get(sys.argv[2]))" "$HOME/.claude/settings.json" "$1"; }

# style file content
assert_contains "$(head -5 "$STYLE_SRC")" "name: Concise Custom" "style has name"
assert_contains "$(head -5 "$STYLE_SRC")" "keep-coding-instructions: true" "style keeps coding instructions"
assert_contains "$(cat "$STYLE_SRC")" "Lead with the result" "style has built-in rule 1"
assert_contains "$(cat "$STYLE_SRC")" "Write in ASD-STE100" "style has addition"
assert_contains "$(cat "$STYLE_SRC")" "these rules win" "style has precedence line"

# merge into existing settings: forced keys set, others kept
make_sandbox; S="$HOME/.claude/settings.json"
echo '{"model":"opus","theme":"dark"}' > "$S"
python3 "$MERGE" "$S"; assert_eq 0 $? "merge exit 0"
assert_eq sonnet "$(val model)" "model forced to sonnet"
assert_eq dark "$(val theme)" "other keys kept"
assert_eq opus "$(val advisorModel)" "advisorModel set"
assert_eq "Concise Custom" "$(val outputStyle)" "outputStyle set"
python3 "$MERGE" --dry "$S"; assert_eq 0 $? "--dry exit 0 when current"
echo '{"theme":"dark"}' > "$S"
python3 "$MERGE" --dry "$S"; assert_eq 10 $? "--dry exit 10 when change needed"
assert_eq None "$(val model)" "--dry does not write"

# missing and empty files
make_sandbox; S="$HOME/.claude/settings.json"
python3 "$MERGE" "$S"; assert_eq sonnet "$(val model)" "missing file created"
: > "$S"; python3 "$MERGE" "$S"; assert_eq sonnet "$(val model)" "empty file handled"

# invalid JSON untouched
make_sandbox; S="$HOME/.claude/settings.json"; echo '{oops' > "$S"; before=$(cksum < "$S")
python3 "$MERGE" "$S" 2>/dev/null; assert_eq 1 $? "invalid JSON exit 1"
assert_eq "$before" "$(cksum < "$S")" "invalid JSON file byte-identical"

# step 06
make_sandbox; S="$HOME/.claude/settings.json"; echo '{"theme":"dark"}' > "$S"
out=$(step 06-settings); assert_eq 0 $? "step 06 ok"
assert_eq 1 "$(baks settings.json)" "step 06 backs up existing file"
out=$(step 06-settings)
assert_contains "$out" "already current" "step 06 second run is no-op"
assert_eq 1 "$(baks settings.json)" "no extra backup on unchanged re-run"
echo '{oops' > "$S"; out=$(step 06-settings); assert_eq 1 $? "step 06 invalid JSON FAILED"
assert_contains "$out" "reason:" "step 06 failure has reason"
assert_eq '{oops' "$(cat "$S")" "step 06 leaves invalid file untouched"

# step 05
make_sandbox; D="$HOME/.claude/output-styles/concise-custom.md"
out=$(step 05-style); assert_eq 0 $? "step 05 ok"
assert_eq 0 "$(cmp -s "$STYLE_SRC" "$D"; echo $?)" "style copied identically"
out=$(step 05-style); assert_contains "$out" "already current" "step 05 re-run no-op"
assert_eq 0 "$(baks concise-custom.md)" "no backup when identical"
echo changed > "$D"; step 05-style >/dev/null
assert_eq 1 "$(baks concise-custom.md)" "differing file is backed up"
assert_eq 0 "$(cmp -s "$STYLE_SRC" "$D"; echo $?)" "differing file replaced"
finish
