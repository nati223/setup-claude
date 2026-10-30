#!/usr/bin/env bash
# Step 01: install Claude Code (official native installer) and put ~/.local/bin on PATH.

ensure_bashrc_path() {
  local rc="$HOME/.bashrc"
  if [ -f "$rc" ] && grep -q '\.local/bin' "$rc"; then return 0; fi
  if [ "${DRY_RUN:-0}" = 1 ]; then log "[dry-run] would add ~/.local/bin to PATH in $rc"; return 0; fi
  printf '\n# Added by setup_claude\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
}

step_run() {
  local url="${CLAUDE_INSTALL_URL:-https://claude.ai/install.sh}" tmp
  ensure_path
  if have claude; then
    ensure_bashrc_path
    log "reason: already installed $(claude --version 2>/dev/null)"
    return 0
  fi

  tmp="$(mktemp)"
  if ! run curl -fsSL --max-time 120 "$url" -o "$tmp"; then
    rm -f "$tmp"; log "reason: download failed ($url)"; return 1
  fi
  if ! run bash "$tmp"; then
    rm -f "$tmp"; log "reason: installer script failed"; return 1
  fi
  rm -f "$tmp"
  [ "${DRY_RUN:-0}" = 1 ] && { ensure_bashrc_path; return 0; }

  if ! have claude; then log "reason: installer ran but claude is not on PATH"; return 1; fi
  ensure_bashrc_path
  log "run: source ~/.bashrc   (or open a new terminal)"
  log "reason: installed $(claude --version 2>/dev/null)"
}
