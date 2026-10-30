#!/usr/bin/env bash
# Step 03 (runs before graphify so graphify finds its name in CLAUDE.md and adds nothing): install config/CLAUDE.md as a marked block inside ~/.claude/CLAUDE.md.

step_run() {
  local target="$HOME/.claude/CLAUDE.md" cfg="$REPO_DIR/config/CLAUDE.md"
  local tool="$REPO_DIR/lib/replace_block.py" rc
  have python3 || { log "reason: python3 not found"; return 1; }
  python3 "$tool" --dry "$target" "$cfg"; rc=$?
  case "$rc" in
    0) log "reason: already current"; return 0 ;;
    10) ;;
    1) log "reason: unmatched setup-claude marker in $target; fix it by hand. File untouched"; return 1 ;;
    *) log "reason: could not prepare $target"; return 1 ;;
  esac
  if [ "${DRY_RUN:-0}" = 1 ]; then log "[dry-run] would update the setup-claude block in $target"; return 0; fi
  if [ -s "$target" ]; then
    backup_file "$target"
    grep -qF '<!-- setup-claude:begin -->' "$target" ||
      log "warning: $target had rules outside the setup-claude block; they may now appear twice. Check it."
  fi
  python3 "$tool" "$target" "$cfg" || { log "reason: write failed"; return 1; }
  log "reason: updated setup-claude block in $target"
}
