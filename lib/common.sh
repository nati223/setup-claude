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

# Copy a file to <file>.bak.<timestamp>. A missing file is not an error.
backup_file() {
  [ -e "$1" ] || return 0
  cp -p "$1" "$1.bak.$(date +%Y%m%d%H%M%S)"
}

# Run a command, or only print it when DRY_RUN=1.
run() {
  if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}
