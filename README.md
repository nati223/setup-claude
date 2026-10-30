# setup_claude

One command that rebuilds my Claude Code setup on a fresh Linux server.

```bash
git clone <this repo> && cd setup_claude
bash install.sh
source ~/.bashrc     # so `claude` is on PATH in this terminal
claude               # log in (not automated)
```

Each step runs on its own. A failing step is reported and the run continues. The summary at the end shows `OK`, `FAILED`, `SKIPPED` or `DRY` for every step. The exit code is 1 if any step failed. Re-running is safe.

## What it installs

| Step | What |
|---|---|
| 01 claude | Claude Code (official installer) and `~/.local/bin` on PATH |
| 02 plugins | superpowers, qmd, andrej-karpathy-skills, claude-handoff (from plugin marketplaces) |
| 03 graphify | `uv` (if missing), then `graphifyy` and its Claude skill |
| 04 qmd-cli | the `qmd` CLI (`@tobilu/qmd`; needs Node 22+ or bun; the plugin needs it) |
| 05 style | output style `Concise Custom` in `~/.claude/output-styles/` |
| 06 settings | sets `model: sonnet`, `advisorModel: opus`, `outputStyle: Concise Custom` in `~/.claude/settings.json`; other keys stay; backup first |
| 07 claude-md | a marked block in `~/.claude/CLAUDE.md` (qmd/graphify rules, code-review standards); text outside the block stays |
| 90 headroom | optional, only with `--with-headroom` |

## Flags

```
bash install.sh [--only STEP]... [--skip STEP]... [--with-headroom] [--dry-run]
```

`STEP` is a number (`03`) or a name (`graphify`). `--dry-run` prints what would happen and changes nothing.

## Notes

- **qmd searches text files only** (md, txt, code). PDF and DOCX are not searchable in qmd. HTML indexes as raw markup (noisy). Create collections yourself, for example `qmd collection add ~/notes --name notes --mask "**/*.{md,txt}"`.
- **The style is a copy.** `config/output-styles/concise-custom.md` holds the text of Claude Code 2.1.314's built-in Concise style plus four additions. If Anthropic changes the built-in style, this copy does not follow.
- **Existing `CLAUDE.md` without markers:** the script backs it up and appends the block. Rules may then appear twice. Check the file.
- **`headroom`:** off by default. With the flag, it installs the CLI and plugin. It does not run `headroom wrap claude`; do that by hand.
- Claude is not logged in by the script.

## Tests

```bash
bash tests/run.sh
shellcheck -x -S warning install.sh lib/*.sh steps/*.sh tests/*.sh
```

All tests run in a throwaway `HOME` with fake `claude`, `uv`, `npm` and similar tools.

## License

MIT. See `LICENSE`.
