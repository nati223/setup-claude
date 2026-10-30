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
| 03 claude-md | a short marked block in `~/.claude/CLAUDE.md`: one search-order rule (graphify, then qmd, then Read/Grep) and the code-review standards. It does not repeat what the qmd skill and graphify already tell Claude. Text outside the block stays. Runs before graphify on purpose: graphify then finds its name in the file and adds nothing |
| 04 qmd-cli | the `qmd` CLI (`@tobilu/qmd`) with bun (the bun installer is run if bun is missing; it needs `unzip`). Falls back to npm with Node 22+. The plugin needs this command |
| 05 style | output style `Concise Custom` in `~/.claude/output-styles/` |
| 06 settings | sets `model: sonnet`, `advisorModel: opus`, `outputStyle: Concise Custom` in `~/.claude/settings.json`; other keys stay; file mode and symlinks kept |
| 07 graphify | `uv` (if missing), then `graphifyy` and its Claude skill |
| 90 headroom | optional, only with `--with-headroom` |

## Flags

```
bash install.sh [--only STEP]... [--skip STEP]... [--with-headroom] [--dry-run]
```

`STEP` is a number (`03`) or a name (`graphify`). `--dry-run` prints what would happen and changes nothing.

## External tools and where they come from

| Tool | Installed by | Source |
|---|---|---|
| Claude Code | step 01 | [setup docs](https://code.claude.com/docs/en/setup) |
| superpowers (plugin) | step 02, marketplace `claude-plugins-official` | [obra/superpowers](https://github.com/obra/superpowers), [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) |
| qmd (plugin) | step 02, marketplace `qmd` | [tobi/qmd](https://github.com/tobi/qmd) |
| andrej-karpathy-skills (plugin) | step 02, marketplace `karpathy-skills` | [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) |
| claude-handoff (plugin) | step 02, marketplace `claude-handoff` | [392fyc/claude-handoff](https://github.com/392fyc/claude-handoff) |
| qmd CLI (`@tobilu/qmd`) | step 04 (bun; npm as fallback) | [tobi/qmd](https://github.com/tobi/qmd) |
| bun | step 04, only if missing | [bun.sh](https://bun.sh) |
| graphify (`graphifyy` on PyPI) | step 07 (uv; no plugin marketplace entry exists) | [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) |
| uv | step 07, only if missing | [astral-sh/uv](https://github.com/astral-sh/uv) |
| headroom (optional) | step 90, marketplace `headroom-marketplace` | [chopratejas/headroom](https://github.com/chopratejas/headroom) |

The output style is based on the built-in Concise style described in the [output styles docs](https://code.claude.com/docs/en/output-styles).

## Backups and timeouts

- Before any step runs, `settings.json` and `CLAUDE.md` are copied to `<file>.bak.<time>` (skipped when an identical backup exists). `claude plugin ...` rewrites `settings.json` itself, so this has to come first.
- Network commands stop after `NET_TIMEOUT` seconds (default 900). Git never asks for a password.

## Notes

- **qmd per project** (not scripted): `qmd collection add ./proj --name proj --mask "**/*.{md,txt,py}"`, then `qmd embed` for semantic search, `qmd update` after changes, `qmd status` to check. The plugin registers qmd's MCP server itself, so no `~/.claude/mcp.json` entry is needed.
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
