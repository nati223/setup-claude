#!/usr/bin/env python3
"""Merge the owner's forced keys into a Claude settings.json, keeping all other keys.

Usage: merge_settings.py [--dry] PATH
Exit: 0 done (or already current), 10 (--dry) change needed, 1 invalid JSON / error.
A missing or empty file counts as {}. Invalid JSON leaves the file untouched.
"""
import json
import os
import sys

FORCED = {"model": "sonnet", "advisorModel": "opus", "outputStyle": "Concise Custom"}


def main(argv):
    dry = "--dry" in argv
    paths = [a for a in argv if not a.startswith("--")]
    if len(paths) != 1:
        print("usage: merge_settings.py [--dry] PATH", file=sys.stderr)
        return 1
    path = paths[0]
    data = {}
    if os.path.exists(path) and os.path.getsize(path) > 0:
        try:
            with open(path) as f:
                data = json.load(f)
        except ValueError as e:
            print(f"invalid JSON in {path}: {e}", file=sys.stderr)
            return 1
        if not isinstance(data, dict):
            print(f"{path} is not a JSON object", file=sys.stderr)
            return 1
    merged = {**data, **FORCED}
    if os.path.exists(path) and merged == data:
        return 0
    if dry:
        return 10
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(merged, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
