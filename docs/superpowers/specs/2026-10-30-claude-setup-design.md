# Claude setup repo: one-command install of Claude Code preferences

Date: 2026-10-30. Status: draft for owner approval.

## Intent
The owner has tuned Claude Code on one machine (plugins, a response style, model choice, global CLAUDE.md rules). They want a repo, publishable later, where `bash install.sh` rebuilds that setup on a fresh Linux server. A failing step must not stop the others.

## Goals
1. One master script (`install.sh`) runs numbered step scripts. Each step reports OK / FAILED / SKIPPED. The script prints a summary table at the end. Exit code is non-zero if any step failed.
2. Re-running is safe (idempotent). Nothing is overwritten without a backup.
3. Install order of preference per tool: Claude plugin marketplace, then git, then npx/pip/npm. (Owner's rule.)
4. Config lives as files in the repo and is copied or merged into `~/.claude/`.

## Non-goals
- Logging in to Claude (`claude` auth stays manual; the README says so).
- Other plugins on the owner's laptop (matlab, academic-research, understand-anything, answer-me-with-html, caveman). Caveman is removed on purpose.
- Building graphify graphs or qmd collections for any project. Those are per-project.
- Converting PDF/DOCX for qmd.
- macOS or Windows support. Debian/Ubuntu-like Linux, bash only.

## Anti-goals (failure even if it "works")
- Replacing the user's existing `~/.claude/settings.json` or `CLAUDE.md` without a backup.
- Any secret, token or personal path committed to the repo.
- One failed step aborting the run.

## Steps (owner-approved content unless marked "my call")
| # | Step | What it does |
|---|------|--------------|
| 01 | claude | `curl -fsSL https://claude.ai/install.sh \| bash`. Add `~/.local/bin` to PATH in `~/.bashrc` if missing. Export PATH inside the script too (my call: Ubuntu's default `~/.bashrc` returns early in non-interactive shells, so sourcing it inside the script is unreliable). Print "run `source ~/.bashrc`" at the end. A script cannot change its parent shell. Verify with `claude --version`. |
| 02 | plugins | `claude plugin marketplace add` then `claude plugin install` for: `superpowers@claude-plugins-official`, `qmd@qmd` (repo `tobi/qmd`), `andrej-karpathy-skills@karpathy-skills` (repo `forrestchang/andrej-karpathy-skills`), `claude-handoff@claude-handoff` (repo `392fyc/claude-handoff`; owner accepted this default; marketplace and plugin name checked in its `marketplace.json`). Each plugin is its own sub-step so one failure does not block the rest. The builder must confirm exact flags with `claude plugin --help`. |
| 03 | graphify | Ensure `uv` exists: already installed, else `pip install --user uv`, else the `astral.sh` installer. (Owner asked for pip; Debian 12 / Ubuntu 23.04+ block system pip with PEP 668, so the fallbacks are my call.) Then `uv tool install graphifyy` and `graphify install`. graphify has no plugin marketplace (verified: 404). The PyPI name is `graphifyy` (two y). |
| 04 | qmd-cli | The qmd plugin only wires the skill and an MCP server that runs `qmd mcp`. It needs the `qmd` CLI on PATH. Install `@tobilu/qmd` with npm (Node 22+), else bun. If neither exists, report FAILED with the reason. (my call: do not install Node automatically.) |
| 05 | style | Copy `config/output-styles/concise-custom.md` to `~/.claude/output-styles/`. Text approved by owner (see below). |
| 06 | settings | Merge, never overwrite, into `~/.claude/settings.json`: `"model": "sonnet"`, `"advisorModel": "opus"`, `"outputStyle": "Concise Custom"`. Use `python3` only (no `jq`; one code path is simpler to test). Back up the old file first. The builder must check that `outputStyle` takes the style's `name` value, and fix it if not. |
| 07 | claude-md | Install `config/CLAUDE.md` into `~/.claude/CLAUDE.md` inside a marked block (`<!-- setup-claude:begin -->` ... `end`). Re-runs replace only that block. Content: the owner's current rules minus "How to Respond" (it moved to the style): qmd-before-read rule, graphify rule, Office skills note, Code Review Standards. Add one comment line: qmd is for non-binary text files only. |
| opt | headroom | Only with `--with-headroom`. Owner decision: off by default. Marketplace `chopratejas/headroom`, plugin `headroom`. The builder must read its README for extra install needs (the Python package, `headroom wrap claude`) and implement only what is needed to install; do not wrap Claude automatically. |

## The response style (approved)
File: `config/output-styles/concise-custom.md`. Frontmatter `name: Concise Custom`, `keep-coding-instructions: true`. Body: the built-in Concise text, verbatim (extracted from Claude Code 2.1.314), then four additions: test the user's premise; hold position under pushback; label confidence (Certain / Likely / Assumption) only when it is not obvious, one clause; write in ASD-STE100. Last line: "Where these rules conflict with more general communication or formatting guidance elsewhere in your instructions, these rules win."

Decisions the owner made:
- Rule "be concise, lead with the answer" is dropped (built-in covers it).
- Rule "pick the likeliest interpretation and proceed" is dropped everywhere. It contradicts the Karpathy guideline and superpowers brainstorming.
- The file carries a comment with the Claude Code version the text came from. Anthropic may change the built-in Concise text later. The clone will not follow it.

## Facts found (verified in this session)
- qmd indexes text only. `.txt` and `.md` work. `.docx` indexes as empty. `.pdf` indexes as raw bytes (useless). `.html` indexes as raw markup: keywords are found, but tags, CSS and script text are indexed too, and the score showed 0%. So html is noisy; leave it out of the default mask.
- Default qmd mask for the script's docs: `**/*.{md,txt}`. The script does not create collections.
- The qmd plugin ships two skills (`qmd`, `release`) and an MCP server. The `qmd` skill triggers on requests like "find notes", "answer from indexed markdown". It does not trigger on every file read. The global CLAUDE.md rule "use qmd before reading files" is what drives the habit, so keep that rule.

## Layout
```
setup_claude/
  install.sh                  master
  lib/common.sh               run_step, logging, summary
  steps/01-claude.sh ... 07-claude-md.sh, 90-headroom.sh
  config/CLAUDE.md
  config/output-styles/concise-custom.md
  README.md
  docs/superpowers/specs/     this file
```
Flags: `--only <step>`, `--skip <step>`, `--with-headroom`, `--dry-run`.

## Testing (left to the builder)
Run with a throwaway `HOME` (and `XDG_CONFIG_HOME` / `XDG_CACHE_HOME`) so the real `~/.claude` is not touched. Check: idempotent second run, a forced failure in one step still lets the rest run, backups created, summary and exit code correct, `--dry-run` changes nothing. `shellcheck` clean.

## Calls made after the builder check (my calls; owner can change)
- **Step states.** OK = installed now, or verified already present (the log line says which). SKIPPED = left out on purpose (`--skip`, not in `--only`, headroom not requested). FAILED = tried and did not work, with the reason. `--dry-run` prints what would happen and reports every step as DRY.
- **Selection flags.** `--only` and `--skip` take a step number (`03`) or name (`graphify`), and can repeat.
- **Prerequisites.** Every step sources `lib/common.sh`, which puts `~/.local/bin` on PATH. A step whose prerequisite is missing (no `claude` for 02, no npm or bun for 04) runs, then reports FAILED with the reason. It is not SKIPPED. No step is blocked by another step's failure.
- **Existing CLAUDE.md without markers.** Back it up, append the marked block, and print a warning that rules may now appear twice. No attempt to find old copies. The target is a fresh server.
- **Existing settings values.** Step 06 forces the three owner keys (`model`, `advisorModel`, `outputStyle`) even if set differently, because reproducing the owner's setup is the purpose. It keeps every other key and backs up first. If `settings.json` is not valid JSON, the step reports FAILED and leaves the file untouched.
- **Pinning.** No version pins, no minimum-version check. `curl | bash` for Claude is accepted because it is the official method. If a newer Claude Code rejects a flag or key, the step fails loudly.
- **`advisorModel`.** It is a real key: it is already in the owner's working `settings.json`.

## Left to the builder
Script style, log format, exact CLI flags, how to detect "already installed", README wording.

## Open items for the owner
- Run `git init` in this folder? (Not a git repo now. Needed to commit the spec and publish later.)
- License for the public repo.
