#!/usr/bin/env bash
# Step 05: install the Concise Custom output style.

step_run() {
  local src="$REPO_DIR/config/output-styles/concise-custom.md"
  local dest_dir="$HOME/.claude/output-styles" dest
  dest="$dest_dir/concise-custom.md"
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then log "reason: already current"; return 0; fi
  run mkdir -p "$dest_dir" || { log "reason: cannot create $dest_dir"; return 1; }
  if [ "${DRY_RUN:-0}" != 1 ]; then backup_file "$dest"; fi
  run cp "$src" "$dest" || { log "reason: copy to $dest failed"; return 1; }
  log "reason: installed $dest"
}
