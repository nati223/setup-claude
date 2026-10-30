#!/usr/bin/env bash
# Test helpers: sandbox HOME, assertions. Source this from test_*.sh.
export REPO_DIR; REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILS=0

make_sandbox() {
  SANDBOX="$(mktemp -d)"
  export SANDBOX
  export HOME="$SANDBOX/home dir"
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_CACHE_HOME="$HOME/.cache"
  mkdir -p "$HOME/.claude"
}

assert_eq() {
  if [ "$1" = "$2" ]; then echo "PASS: $3"; else echo "FAIL: $3 (expected '$1', got '$2')"; FAILS=$((FAILS + 1)); fi
}

assert_contains() {
  case "$1" in *"$2"*) echo "PASS: $3" ;; *) echo "FAIL: $3 ('$2' not in output)"; FAILS=$((FAILS + 1)) ;; esac
}

finish() { [ "$FAILS" -eq 0 ]; exit $?; }
