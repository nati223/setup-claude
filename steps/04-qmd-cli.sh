#!/usr/bin/env bash
# Step 04: install the qmd CLI with bun (the qmd plugin only wires the skill and MCP server to it).
# Order: bun (installed with the official installer if missing; it needs unzip) -> npm as a fallback.
# qmd needs Node >= 22 on the npm path. Node is never installed here.
# qmd searches text only (md, txt, code). PDF and DOCX are not indexed usefully.

BUN_WHY=""

ensure_bun() {
  local tmp
  have bun && return 0
  if ! have unzip; then BUN_WHY="bun installer needs unzip (apt install unzip)"; return 1; fi
  tmp="$(mktemp)"
  if run curl -fsSL --max-time 120 "${BUN_INSTALL_URL:-https://bun.sh/install}" -o "$tmp" && run_net bash "$tmp"; then
    export PATH="$HOME/.bun/bin:$PATH"
  else
    BUN_WHY="bun installer failed"
  fi
  rm -f "$tmp"
  have bun || [ "${DRY_RUN:-0}" = 1 ]
}

npm_install_qmd() {
  local major
  have npm || { BUN_WHY="${BUN_WHY:+$BUN_WHY; }no npm"; return 1; }
  major="$(node -v 2>/dev/null | sed 's/^v//; s/\..*//')"
  if [ -z "$major" ] || [ "$major" -lt 22 ] 2>/dev/null; then
    BUN_WHY="${BUN_WHY:+$BUN_WHY; }node $(node -v 2>/dev/null || echo missing) is too old (qmd needs Node >= 22)"
    return 1
  fi
  run_net npm install -g --prefix "$HOME/.local" @tobilu/qmd
}

step_run() {
  ensure_path
  export PATH="$HOME/.bun/bin:$PATH"
  if have qmd; then log "reason: already installed"; return 0; fi

  if ensure_bun && run_net bun install -g @tobilu/qmd; then
    :
  elif npm_install_qmd; then
    :
  else
    log "reason: need bun (${BUN_WHY:-bun install failed}) or npm with Node 22+"
    return 1
  fi

  [ "${DRY_RUN:-0}" = 1 ] && return 0
  have qmd || { log "reason: install ran but qmd is not on PATH"; return 1; }
  log "reason: installed qmd $(qmd --version 2>/dev/null)"
}
