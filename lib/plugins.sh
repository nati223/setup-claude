#!/usr/bin/env bash
# Plugin install helper shared by steps 02 and 90. Needs lib/common.sh. CLAUDE_BIN overrides `claude` (tests).

# plugin_install REPO PLUGIN@MARKETPLACE: add the marketplace if unknown, then install. 0 = ok.
plugin_install() {
  local repo="$1" id="$2" market bin="${CLAUDE_BIN:-claude}"
  market="${id#*@}"
  if ! "$bin" plugin marketplace list 2>/dev/null | grep -qE "(^|[^A-Za-z0-9_-])${market}([^A-Za-z0-9_-]|$)"; then
    run "$bin" plugin marketplace add "$repo" || { log "marketplace add failed: $repo"; return 1; }
  fi
  if "$bin" plugin list 2>/dev/null | awk -v id="$id" '$NF == id { f = 1 } END { exit !f }'; then
    log "already installed: $id"
    return 0
  fi
  run "$bin" plugin install "$id" || { log "install failed: $id"; return 1; }
}
