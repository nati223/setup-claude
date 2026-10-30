#!/usr/bin/env bash
# Master installer: runs steps/NN-name.sh in order, reports each, never stops on a failure.
set -u
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$REPO_DIR/lib/common.sh"
STEPS_DIR="${STEPS_DIR:-$REPO_DIR/steps}"
ONLY=() SKIP=() WITH_HEADROOM=0 DRY_RUN=0
export REPO_DIR WITH_HEADROOM DRY_RUN

usage() {
  cat <<'USAGE'
Usage: bash install.sh [--only STEP]... [--skip STEP]... [--with-headroom] [--dry-run]
  STEP is a number (03) or a name (graphify). --only and --skip can repeat.
  --with-headroom  also install the optional headroom plugin
  --dry-run        print what would happen; change nothing
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --only) [ $# -ge 2 ] || { usage; exit 2; }; ONLY+=("$2"); shift 2 ;;
    --skip) [ $# -ge 2 ] || { usage; exit 2; }; SKIP+=("$2"); shift 2 ;;
    --with-headroom) WITH_HEADROOM=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
export WITH_HEADROOM DRY_RUN

# matches ID LIST...: true if the step number or name is in LIST.
matches() {
  local id="$1" item; shift
  for item in "$@"; do
    [ "$item" = "${id%%-*}" ] || [ "$item" = "${id#*-}" ] && return 0
  done
  return 1
}

export GIT_TERMINAL_PROMPT=0   # a renamed or deleted marketplace repo must fail, not wait for a password

# Back up the files that steps (or the tools they call) rewrite, before any step runs.
if [ "$DRY_RUN" != 1 ]; then
  backup_file "$HOME/.claude/settings.json"
  backup_file "$HOME/.claude/CLAUDE.md"
fi

RESULTS=() FAILED=0
record() { # status id reason
  RESULTS+=("$(printf '%-9s%s%s' "$1" "$2" "${3:+  $3}")")
  [ "$1" = FAILED ] && FAILED=$((FAILED + 1))
}

for f in "$STEPS_DIR"/*.sh; do
  [ -e "$f" ] || continue
  id="$(basename "$f" .sh)"
  if [ ${#ONLY[@]} -gt 0 ] && ! matches "$id" "${ONLY[@]}"; then record SKIPPED "$id" "not selected"; continue; fi
  if [ ${#SKIP[@]} -gt 0 ] && matches "$id" "${SKIP[@]}"; then record SKIPPED "$id" "--skip"; continue; fi
  if [ "${id#*-}" = headroom ] && [ "$WITH_HEADROOM" != 1 ]; then record SKIPPED "$id" "needs --with-headroom"; continue; fi

  log "=== $id"
  tmp="$(mktemp)"
  # shellcheck disable=SC1090
  ( source "$f"; step_run ) 2>&1 | tee "$tmp"
  rc="${PIPESTATUS[0]}"
  reason="$(grep '^\[setup\] reason:' "$tmp" | tail -1 | sed 's/^\[setup\] reason: *//')"
  rm -f "$tmp"
  case "$rc" in
    0) if [ "$DRY_RUN" = 1 ]; then record DRY "$id" "$reason"; else record OK "$id" "$reason"; fi ;;
    3) record SKIPPED "$id" "$reason" ;;
    *) record FAILED "$id" "${reason:-exit code $rc}" ;;
  esac
done

echo
echo "Summary"
printf '%s\n' "${RESULTS[@]}"
[ "$FAILED" -eq 0 ]
