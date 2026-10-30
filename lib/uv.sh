#!/usr/bin/env bash
# uv helper shared by steps 03 and 90. Needs lib/common.sh. UV_INSTALL_URL overrides the astral installer URL (tests).

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
