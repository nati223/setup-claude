#!/usr/bin/env bash
# Step 90 (optional, --with-headroom): headroom context-compression layer.
# Installs the headroom CLI (the plugin's hooks call it) and the Claude plugin.
# It does NOT run `headroom wrap claude`: that changes how Claude is launched, so the owner enables it by hand.
# shellcheck source=lib/plugins.sh
source "$REPO_DIR/lib/plugins.sh"
# shellcheck source=lib/uv.sh
source "$REPO_DIR/lib/uv.sh"

step_run() {
  ensure_path
  have "${CLAUDE_BIN:-claude}" || { log "reason: claude not found (run step 01)"; return 1; }
  ensure_uv || { log "reason: could not install uv"; return 1; }
  if ! have headroom; then
    run uv tool install --python 3.13 "headroom-ai[all]" || { log "reason: uv tool install headroom-ai failed"; return 1; }
  fi
  plugin_install chopratejas/headroom headroom@headroom-marketplace || { log "reason: headroom plugin install failed"; return 1; }
  log "to enable it, run by hand: headroom wrap claude   (undo: headroom unwrap claude)"
  log "reason: headroom CLI and plugin installed"
}
