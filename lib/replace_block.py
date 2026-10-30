#!/usr/bin/env python3
"""Insert or replace the setup-claude marked block in a CLAUDE.md.

Usage: replace_block.py [--dry] TARGET CONFIG
CONFIG holds the block body. Text outside the markers is never changed.
Exit: 0 done (or already current), 10 (--dry) change needed, 1 unmatched begin marker (file untouched).
"""
import os
import stat
import sys

BEGIN = "<!-- setup-claude:begin -->"
END = "<!-- setup-claude:end -->"


def main(argv):
    dry = "--dry" in argv
    target, config = [a for a in argv if not a.startswith("--")]
    with open(config) as f:
        block = f"{BEGIN}\n{f.read().rstrip(chr(10))}\n{END}"
    old = ""
    if os.path.exists(target):
        with open(target) as f:
            old = f.read()
    i = old.find(BEGIN)
    j = old.find(END, i) if i >= 0 else -1
    if i >= 0 and j < 0:
        print(f"unmatched {BEGIN} in {target}: no {END} after it", file=sys.stderr)
        return 1
    if i >= 0:
        new = old[:i] + block + old[j + len(END):]
    elif old.strip():
        new = old.rstrip("\n") + "\n\n" + block + "\n"
    else:
        new = block + "\n"
    if os.path.exists(target) and new == old:
        return 0
    if dry:
        return 10
    target = os.path.realpath(target)  # write through a symlink instead of replacing it
    os.makedirs(os.path.dirname(target) or ".", exist_ok=True)
    tmp = target + ".tmp"
    with open(tmp, "w") as f:
        f.write(new)
    if os.path.exists(target):
        os.chmod(tmp, stat.S_IMODE(os.stat(target).st_mode))  # keep 600 etc.
    os.replace(tmp, target)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
