#!/usr/bin/env bash
# Step 04: install the qmd CLI (the qmd plugin only wires the skill and MCP server to it).
# npm installs into ~/.local so no sudo is needed. Node is never installed here. qmd needs Node >= 22.
# qmd searches text only (md, txt, code). PDF and DOCX are not indexed usefully.

step_run() {
  local major
  ensure_path
  export PATH="$HOME/.bun/bin:$PATH"
  if have qmd; then log "reason: already installed"; return 0; fi

  if have npm; then
    major="$(node -v 2>/dev/null | sed 's/^v//; s/\..*//')"
    if [ -z "$major" ] || [ "$major" -lt 22 ] 2>/dev/null; then
      log "reason: node $(node -v 2>/dev/null || echo missing) is too old; qmd needs Node >= 22"
      return 1
    fi
    run npm install -g --prefix "$HOME/.local" @tobilu/qmd || { log "reason: npm install @tobilu/qmd failed"; return 1; }
  elif have bun; then
    run bun install -g @tobilu/qmd || { log "reason: bun install @tobilu/qmd failed"; return 1; }
  else
    log "reason: need npm (Node 22+) or bun"
    return 1
  fi

  [ "${DRY_RUN:-0}" = 1 ] && return 0
  have qmd || { log "reason: install ran but qmd is not on PATH"; return 1; }
  log "reason: installed qmd $(qmd --version 2>/dev/null)"
}
