#!/usr/bin/env bash
# Test helpers: sandbox HOME, assertions. Source this from test_*.sh.
export REPO_DIR; REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILS=0
: "${ORIG_PATH:=$PATH}"; export ORIG_PATH

make_sandbox() {
  export PATH="$ORIG_PATH"
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

# make_min_path: narrow PATH to a few system tools plus $SANDBOX/fake (for fake_cmd). Hides real pip/npm/uv.
make_min_path() {
  mkdir -p "$SANDBOX/bin" "$SANDBOX/fake"
  local c p
  for c in bash sh curl ln mktemp date cp mkdir grep awk sed cat rm dirname basename tee head tail tr wc cmp find ls env uname readlink cksum sort touch chmod python3; do
    p="$(command -v "$c")"
    case "$p" in /*) ln -sf "$p" "$SANDBOX/bin/$c" ;; esac
  done
  export PATH="$SANDBOX/fake:$SANDBOX/bin"
  export FAKE_LOG="$SANDBOX/calls.log"; : > "$FAKE_LOG"
}

# fake_cmd NAME BODY: create $SANDBOX/fake/NAME that logs "NAME args" to $FAKE_LOG, then runs BODY.
fake_cmd() {
  printf '#!/bin/bash\necho "%s $*" >> "$FAKE_LOG"\n%s\n' "$1" "${2:-exit 0}" > "$SANDBOX/fake/$1"
  chmod +x "$SANDBOX/fake/$1"
}
