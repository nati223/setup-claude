#!/usr/bin/env bash
# Step 07: ensure uv, then install graphify (PyPI name: graphifyy) and register its Claude skill.
# graphify has no plugin marketplace entry, so this uses uv. `graphify install --platform claude`
# registers the skill under ~/.claude/skills.

# shellcheck source=lib/uv.sh
source "$REPO_DIR/lib/uv.sh"

step_run() {
  if have graphify && [ -f "$HOME/.claude/skills/graphify/SKILL.md" ]; then
    log "reason: graphify already installed and registered"
    return 0
  fi
  ensure_uv || { log "reason: could not install uv"; return 1; }
  if ! have graphify; then
    run_net uv tool install graphifyy || { log "reason: uv tool install graphifyy failed"; return 1; }
    ensure_path
  fi
  run graphify install --platform claude || { log "reason: graphify install failed"; return 1; }
  log "reason: graphify ready"
}
