#!/usr/bin/env bash
# Run every tests/test_*.sh; exit non-zero if any fails.
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failed=0 total=0
for t in "$dir"/test_*.sh; do
  [ -e "$t" ] || continue
  total=$((total + 1))
  echo "== $(basename "$t")"
  bash "$t" || { failed=$((failed + 1)); echo "!! $(basename "$t") FAILED"; }
done
echo "tests: $((total - failed))/$total files passed"
[ "$failed" -eq 0 ]
