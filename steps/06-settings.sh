#!/usr/bin/env bash
# Step 06: force model, advisorModel and outputStyle in ~/.claude/settings.json; keep all other keys.

step_run() {
  local settings="$HOME/.claude/settings.json" merge="$REPO_DIR/lib/merge_settings.py" rc
  have python3 || { log "reason: python3 not found"; return 1; }
  mkdir -p "$HOME/.claude"
  python3 "$merge" --dry "$settings"; rc=$?
  case "$rc" in
    0) log "reason: already current"; return 0 ;;
    10) ;;
    *) log "reason: could not read $settings (see message above); file left untouched"; return 1 ;;
  esac
  if [ "${DRY_RUN:-0}" = 1 ]; then log "[dry-run] would merge settings into $settings"; return 0; fi
  backup_file "$settings"
  python3 "$merge" "$settings" || { log "reason: merge failed"; return 1; }
  log "reason: merged model, advisorModel, outputStyle into $settings"
}
