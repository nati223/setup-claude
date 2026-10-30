#!/usr/bin/env bash
# Step 03: ensure uv, then install graphify (PyPI name: graphifyy) and register its Claude skill.
# graphify has no plugin marketplace entry, so this uses uv. `graphify install --platform claude`
# registers the skill under ~/.claude/skills.

# shellcheck source=lib/uv.sh
source "$REPO_DIR/lib/uv.sh"

step_run() {
  ensure_uv || { log "reason: could not install uv"; return 1; }
  if ! have graphify; then
    run uv tool install graphifyy || { log "reason: uv tool install graphifyy failed"; return 1; }
    ensure_path
  fi
  run graphify install --platform claude || { log "reason: graphify install failed"; return 1; }
  log "reason: graphify ready"
}
