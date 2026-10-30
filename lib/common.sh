#!/usr/bin/env bash
# Shared helpers for install.sh and steps/*.sh.

log() { printf '[setup] %s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Put ~/.local/bin on PATH for this shell, once.
ensure_path() {
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
}

# Copy a file to <file>.bak.<timestamp>[.n]. A missing file is not an error.
# Skips when an existing backup already has identical content. Never overwrites a backup.
backup_file() {
  local f="$1" b dest n=0 ts
  [ -e "$f" ] || return 0
  for b in "$f".bak.*; do
    [ -e "$b" ] && cmp -s "$f" "$b" && return 0
  done
  ts="$(date +%Y%m%d%H%M%S)"
  dest="$f.bak.$ts"
  while [ -e "$dest" ]; do n=$((n + 1)); dest="$f.bak.$ts.$n"; done
  cp -p "$f" "$dest"
}

# Run a command, or only print it when DRY_RUN=1.
run() {
  if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

# Like run, but bounded by NET_TIMEOUT seconds (default 900) so a stalled download cannot hang the script.
run_net() {
  if [ "${DRY_RUN:-0}" != 1 ] && have timeout; then
    timeout "${NET_TIMEOUT:-900}" "$@"
  else
    run "$@"
  fi
}
