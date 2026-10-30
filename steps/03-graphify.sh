#!/usr/bin/env bash
# Step 03: ensure uv, then install graphify (PyPI name: graphifyy) and register its Claude skill.
# graphify has no plugin marketplace entry, so this uses uv. `graphify install --platform claude`
# registers the skill under ~/.claude/skills.

# uv order: already there -> pip --user (fails on PEP 668 systems) -> astral installer.
ensure_uv() {
  local p tmp
  ensure_path
  have uv && return 0
  for p in pip3 pip; do
    if have "$p"; then
      run "$p" install --user -q uv >/dev/null 2>&1
      ensure_path
      have uv && return 0
      break
    fi
  done
  tmp="$(mktemp)"
  if run curl -LsSf --max-time 120 "${UV_INSTALL_URL:-https://astral.sh/uv/install.sh}" -o "$tmp" && run sh "$tmp"; then
    ensure_path
  fi
  rm -f "$tmp"
  have uv || [ "${DRY_RUN:-0}" = 1 ]
}

step_run() {
  ensure_uv || { log "reason: could not install uv"; return 1; }
  if ! have graphify; then
    run uv tool install graphifyy || { log "reason: uv tool install graphifyy failed"; return 1; }
    ensure_path
  fi
  run graphify install --platform claude || { log "reason: graphify install failed"; return 1; }
  log "reason: graphify ready"
}
