# Claude Setup Repo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `bash install.sh` rebuilds the owner's Claude Code setup on a fresh Linux server; a failing step never stops the others.

**Architecture:** A master script sources `lib/common.sh`, finds `steps/NN-name.sh` files, runs each in its own subshell, records OK / FAILED / SKIPPED / DRY, prints a summary, and exits non-zero if any step failed. Config (style, CLAUDE.md block, settings keys) lives as files under `config/`. Tests are plain bash scripts that run in a throwaway `HOME`.

**Tech Stack:** bash, curl, python3 (JSON merge; `jq` used when present), shellcheck (dev only), git.

**Spec:** `docs/superpowers/specs/2026-10-30-claude-setup-design.md`

## Global Constraints
- Platform: Debian/Ubuntu-like Linux, bash only.
- Install preference per tool: Claude plugin marketplace, then git, then npx/pip/npm.
- Never overwrite `~/.claude/settings.json` or `~/.claude/CLAUDE.md` without a backup first.
- No secrets, tokens or personal paths in the repo.
- Step states: OK (installed now or verified present), SKIPPED (left out on purpose), FAILED (tried, did not work, with reason), DRY (`--dry-run`).
- `--only` / `--skip` take a step number (`03`) or name (`graphify`) and can repeat.
- A missing prerequisite makes the step FAILED with a reason. It is never SKIPPED. No step blocks another.
- No version pins. `curl | bash` is accepted for Claude only.
- Style file: `name: Concise Custom`, `keep-coding-instructions: true`. Settings keys forced: `"model": "sonnet"`, `"advisorModel": "opus"`, `"outputStyle": "Concise Custom"`; all other keys kept.
- Plugin ids: `superpowers@claude-plugins-official`, `qmd@qmd` (repo `tobi/qmd`), `andrej-karpathy-skills@karpathy-skills` (repo `forrestchang/andrej-karpathy-skills`), `claude-handoff@claude-handoff` (repo `392fyc/claude-handoff`). Optional: `headroom` from repo `chopratejas/headroom`, marketplace name `headroom-marketplace`.
- graphify PyPI name is `graphifyy` (two y). qmd CLI package is `@tobilu/qmd`.
- License: MIT.

## Review Focus
1. `HOME` path containing a space, or `~/.bashrc` missing: PATH line is still added once and nothing breaks. (Task 3)
2. `settings.json` missing, empty (0 bytes) or invalid JSON: missing/empty gets created; invalid is FAILED and the file stays byte-identical. (Task 4)
3. Second run of everything: no duplicate PATH line, no second CLAUDE.md block, no second backup churn on unchanged files. (Tasks 3, 5)
4. No network or a hanging download: `curl` has `--max-time`; the step is FAILED, the run continues. (Tasks 3, 6, 7)
5. `claude` or `npm` missing when a later step needs it: FAILED with a readable reason, not a stack trace or a silent OK. (Tasks 6, 7)

---

## File Structure
| File | Responsibility |
|---|---|
| `install.sh` | Parse flags, discover steps, run, summarize, exit code |
| `lib/common.sh` | Shared helpers: `log`, `have`, `ensure_path`, `backup_file`, `run` |
| `steps/NN-*.sh` | One step each; defines `step_run` |
| `config/CLAUDE.md` | Text for the marked block |
| `config/output-styles/concise-custom.md` | The style |
| `tests/run.sh`, `tests/lib.sh`, `tests/test_*.sh` | Test runner, sandbox helper, tests |
| `README.md`, `LICENSE`, `.gitignore` | Docs, MIT, ignores |

**Step contract** (every `steps/NN-name.sh`): sourced inside a subshell by `install.sh`; defines `step_run`; `step_run` returns `0` = OK, `3` = SKIPPED, anything else = FAILED. The last line the step prints with `log` that starts with `reason:` is shown in the summary. Variables available: `REPO_DIR`, `DRY_RUN` (`0`/`1`), `WITH_HEADROOM` (`0`/`1`).

---

### Task 1: Scaffold, test harness, common helpers

**Files:**
- Create: `LICENSE` (MIT, holder "Natanel Nissan", year 2026), `.gitignore` (`*.bak.*`, `.env`), `lib/common.sh`, `tests/lib.sh`, `tests/run.sh`, `tests/test_common.sh`

**Interfaces:**
- Produces in `lib/common.sh`:
  - `log() { ... }` prints `[setup] <args>` to stdout
  - `have() { command -v "$1" >/dev/null 2>&1; }`
  - `ensure_path() { ... }` adds `$HOME/.local/bin` to `PATH` in the current shell if absent
  - `backup_file() { ... }` args: `path`; if file exists, copies to `path.bak.<YYYYmmddHHMMSS>`; returns 0 if file missing
  - `run() { ... }` args: command words; in `DRY_RUN=1` prints `[dry-run] <cmd>` and returns 0, else executes
- Produces in `tests/lib.sh`:
  - `make_sandbox()` creates a temp dir, exports `HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME` inside it, `mkdir -p $HOME/.claude`, prints nothing; sets `SANDBOX`
  - `assert_eq() { ... }` args: `expected actual label`; prints `PASS|FAIL: label`, increments `FAILS` on mismatch
  - `assert_contains() { ... }` args: `haystack needle label`
  - `finish() { ... }` exits non-zero if `FAILS > 0`
- `tests/run.sh` runs every `tests/test_*.sh` with `bash`, prints a total, exits non-zero if any failed.

- [ ] **Step 1: Write failing test** `tests/test_common.sh`: sandbox; `source lib/common.sh`; assert `have bash` returns 0 and `have nonexistent-cmd-xyz` returns 1; assert `ensure_path` twice leaves exactly one `$HOME/.local/bin` in `PATH`; assert `backup_file` on a file creates a `.bak.*` sibling with identical content; assert `backup_file` on a missing file returns 0 and creates nothing; assert `run echo hi` prints `hi` and, with `DRY_RUN=1`, prints a line containing `[dry-run]` and does not execute (use `run touch "$SANDBOX/x"` and assert the file is absent).
- [ ] **Step 2: Run** `bash tests/run.sh` — Expected: FAIL (`lib/common.sh` missing).
- [ ] **Step 3: Implement** the helpers above in `lib/common.sh` and `tests/lib.sh`, `tests/run.sh`. `HOME` must be quoted everywhere (Review Focus 1).
- [ ] **Step 4: Run** `bash tests/run.sh` and `shellcheck lib/*.sh tests/*.sh` — Expected: all PASS, shellcheck clean.
- [ ] **Step 5: Commit** `git add -A && git commit -m "feat: scaffold, MIT license, common helpers, test harness"`

---

### Task 2: Master script `install.sh`

**Files:**
- Create: `install.sh`, `tests/test_master.sh`

**Interfaces:**
- Consumes: `lib/common.sh` (`log`).
- Produces: CLI `bash install.sh [--only X]... [--skip X]... [--with-headroom] [--dry-run] [-h]`. Env `STEPS_DIR` (default `$REPO_DIR/steps`) lets tests point at fake steps. Step selection: a step is selected if `--only` is empty or matches its number or name; it is excluded if `--skip` matches. Excluded steps and `90-headroom` without `--with-headroom` are SKIPPED. Summary lines: `OK|FAILED|SKIPPED|DRY  <NN-name>  <reason>`. Exit code `1` if any FAILED, else `0`. Unknown flag: print usage, exit `2`.

- [ ] **Step 1: Write failing tests** in `tests/test_master.sh` using a temp `STEPS_DIR` with fake steps: `01-a.sh` (returns 0), `02-b.sh` (returns 1 after `log "reason: boom"`), `03-c.sh` (returns 3), `04-d.sh` (returns 0). Assert: run all → output has `FAILED` for `02-b` with `boom`, `OK` for `04-d` (failure did not stop the run), `SKIPPED` for `03-c`, exit code `1`. `--only 01` and `--only a` each run only step 1 (others SKIPPED), exit `0`. `--skip 02 --skip d` skips both by number and name. `--dry-run` sets `DRY_RUN=1` for steps (fake step echoes it). `--bogus` exits `2`. A step that calls `exit 5` directly is FAILED and later steps still run (steps run in a subshell). `90-headroom` is SKIPPED without `--with-headroom` and runs with it.
- [ ] **Step 2: Run** `bash tests/run.sh` — Expected: FAIL.
- [ ] **Step 3: Implement** `install.sh`: `set -u` (not `-e`); each step runs as `( source "$f"; step_run )` with output captured to a temp log and echoed live; the reason is the last `reason:` line. Print the summary table last.
- [ ] **Step 4: Run** tests and `shellcheck install.sh` — Expected: PASS, clean.
- [ ] **Step 5: Commit** `git commit -am "feat: master script with step runner and summary"` (use `git add -A` first).

---

### Task 3: Step 01 — install Claude, fix PATH

**Files:**
- Create: `steps/01-claude.sh`, `tests/test_step01.sh`

**Interfaces:**
- Consumes: `log`, `have`, `ensure_path`, `run`.
- Produces: `step_run` that (a) returns 0 with log `already installed: <version>` if `have claude` after `ensure_path`; (b) otherwise runs `curl -fsSL --max-time 120 https://claude.ai/install.sh | bash`; (c) appends `export PATH="$HOME/.local/bin:$PATH"` to `$HOME/.bashrc` only if no line containing `.local/bin` is there (creates the file if missing); (d) verifies `claude --version`, else returns 1 with `reason:`; (e) logs `run: source ~/.bashrc`. Test hook: env `CLAUDE_INSTALL_URL` overrides the URL.

- [ ] **Step 1: Write failing tests**: sandbox with `HOME` containing a space (`$SANDBOX/home dir`); a local fake installer script served via `file://` that creates `$HOME/.local/bin/claude` printing `9.9.9 (Claude Code)`; assert step OK, `.bashrc` created with exactly one PATH line after running `step_run` twice; assert with an installer URL that fails (`file:///nonexistent`) the step returns non-zero with a `reason:` line and `.bashrc` unchanged; assert `--dry-run` runs no download.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** `steps/01-claude.sh`.
- [ ] **Step 4: Run** tests, shellcheck — Expected: PASS.
- [ ] **Step 5: Commit** `feat: step 01 install claude`.

---

### Task 4: Steps 05 and 06 — style file and settings merge

**Files:**
- Create: `config/output-styles/concise-custom.md`, `steps/05-style.sh`, `steps/06-settings.sh`, `lib/merge_settings.py`, `tests/test_step05_06.sh`

**Interfaces:**
- Produces: `lib/merge_settings.py <settings.json path>`: sets the three forced keys, keeps all others, writes with 2-space indent; exit `0` ok, exit `1` with a message on invalid JSON (file untouched). Missing or 0-byte file → created with just the three keys.
- `05-style.sh`: `mkdir -p ~/.claude/output-styles`; copy the style; if the destination exists and differs, `backup_file` first; identical → log `already current`, OK.
- `06-settings.sh`: `backup_file` then run `merge_settings.py` (python3 required; missing python3 → FAILED with reason). Use `python3` only; no `jq` dependency (decision: one code path).

**Style file content** (exact copy; fixed by spec):

````markdown
---
name: Concise Custom
description: Built-in Concise plus critical-review, no-caving, confidence labels, ASD-STE100
keep-coding-instructions: true
---

<!-- Base text copied from Claude Code 2.1.314 built-in "Concise" style. Anthropic may change the built-in later; this copy does not follow it. -->

Keep your responses short and direct while doing the work just as thoroughly.

The user chose brevity over narration. You should:

1. **Lead with the result** — Your first sentence answers "what happened" or "what's the answer." No preamble ("Let me...", "Now I'll...") and no closing recap of what you already said.
2. **Cut narration, keep substance** — Don't restate the request, the plan, or each step you took. Report outcomes, decisions, and anything the user must act on.
3. **Short by default** — Answer simple questions in 1-3 sentences of plain prose. Use headers, tables, and bullet lists only when they carry real structure, never as decoration.
4. **State things plainly** — Skip hedging boilerplate. Mention a caveat only when it changes what the user should do next.
5. **Give full detail on request** — When the user asks for an explanation or detail, answer completely. Conciseness never means withholding requested information.
6. **Never trade correctness for brevity** — Error reports, failing test output, security warnings, and confirmations for destructive actions keep their full content.

Additions:

7. **Test the user's premise** — Assume the user's claim might be wrong. Evaluate it on its own. Agree only with evidence. If the user is wrong, say so directly.
8. **Hold your position** — If the user pushes back, do not change your answer without a concrete reason. Changing it under social pressure is wrong.
9. **Label confidence when it is not obvious** — Add one clause: Certain (strong evidence), Likely (reasonable inference), or Assumption (limited basis). Say "I don't know" when that is true.
10. **Write in ASD-STE100** — Short sentences, one idea each, active voice, simple words.

Where these rules conflict with more general communication or formatting guidance elsewhere in your instructions, these rules win.
````

- [ ] **Step 1: Write failing tests**: merge into `{}` , into a file with `{"model":"opus","theme":"dark"}` (assert `model`=`sonnet`, `theme` kept, `advisorModel`=`opus`, `outputStyle`=`Concise Custom`); missing file and 0-byte file → created with three keys; invalid JSON (`{oops`) → exit 1 and file byte-identical (compare `cksum`); `06` step creates a `.bak.*` file when a settings file existed; `05` twice → one style file, no extra backup the second time; the style file's frontmatter contains `name: Concise Custom` and `keep-coding-instructions: true`.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** the style file, both steps and `merge_settings.py` (stdlib `json` only).
- [ ] **Step 4: Run tests; verify the value `Concise Custom` is accepted** by the installed Claude Code: in a sandbox `HOME`, copy the style, set `outputStyle`, run `claude --debug -p "hi" 2>&1 | grep -i "output style"` (or `claude doctor`). If the name is not accepted, switch the setting to the file name `concise-custom` and update this plan's Global Constraints and the spec.
- [ ] **Step 5: Commit** `feat: steps 05/06 style file and settings merge`.

---

### Task 5: Step 07 — CLAUDE.md marked block

**Files:**
- Create: `config/CLAUDE.md`, `steps/07-claude-md.sh`, `tests/test_step07.sh`

**Interfaces:**
- `config/CLAUDE.md` holds only the block body (no markers). Sections, copied from the owner's current `~/.claude/CLAUDE.md`: "Rule: always use qmd before reading files" (add one line: `qmd is for non-binary text files only (md, txt, code). PDF and DOCX are not searchable in qmd.`), "graphify", "Office Skills", "Code Review Standards", and the lines "Run /simplify before presenting code to the user" and "When the user types `/graphify`, use the installed graphify skill...". Do NOT include "How to Respond" (moved to the style).
- `07-claude-md.sh` `step_run`: markers `<!-- setup-claude:begin -->` / `<!-- setup-claude:end -->`. No target file → create with the block. Target has markers → replace only between them (identical content → OK, no backup). Target has no markers → `backup_file`, append block, log a `warning:` line that rules may appear twice.

- [ ] **Step 1: Write failing tests**: fresh `HOME` → file has begin/end once; run twice → still one block, file unchanged on second run, no new `.bak.*`; file with `my own rule` and no markers → backup exists, `my own rule` still present, block appended, output contains `warning:`; file with markers and text before and after → text before/after untouched, block body replaced after editing `config/CLAUDE.md` content (use a temp copy via `REPO_DIR` override); `~/.claude` directory missing → created. Assert `config/CLAUDE.md` contains `non-binary` and does not contain `How to Respond`.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** with `python3` or `awk` for the replace; no `sed -i` on user data without backup.
- [ ] **Step 4: Run tests, shellcheck** — Expected: PASS.
- [ ] **Step 5: Commit** `feat: step 07 CLAUDE.md marked block`.

---

### Task 6: Step 02 — plugins

**Files:**
- Create: `steps/02-plugins.sh`, `tests/test_step02.sh`

**Interfaces:**
- Consumes: `have`, `run`, `log`.
- Produces: `step_run` loops over four pairs `(repo-or-empty, plugin@marketplace)`: `("", superpowers@claude-plugins-official)`, `(tobi/qmd, qmd@qmd)`, `(forrestchang/andrej-karpathy-skills, andrej-karpathy-skills@karpathy-skills)`, `(392fyc/claude-handoff, claude-handoff@claude-handoff)`. For each: `claude plugin marketplace add <repo>` (skip if repo empty; the official marketplace is built in — verify; if not, add `anthropics/claude-plugins-official`), then `claude plugin install <id>`. A plugin already installed (check `claude plugin list`) logs `already installed` and counts OK. Each pair is independent: failures are collected, loop continues; step returns 1 with `reason:` listing failed ids, else 0. No `claude` → return 1, `reason: claude not found (run step 01)`.
- Test hook: env `CLAUDE_BIN` (default `claude`) so tests use a fake script that logs its args and can be told to fail for one id.

- [ ] **Step 1: Verify real syntax** — run `claude plugin --help`, `claude plugin marketplace --help`, `claude plugin install --help`, `claude plugin list --help`. Write the exact subcommands into a comment at the top of the step. If they differ from the interface above, update this task's Interfaces and the code.
- [ ] **Step 2: Write failing tests** with a fake `CLAUDE_BIN`: all succeed → fake saw 3 `marketplace add` and 4 `install` calls, step 0; fake fails on `qmd@qmd` → step returns non-zero, `reason:` names `qmd@qmd`, and the other three installs still ran; fake `claude plugin list` shows karpathy installed → no install call for it; `CLAUDE_BIN` missing → non-zero with `claude not found`.
- [ ] **Step 3: Run** — Expected: FAIL.
- [ ] **Step 4: Implement** `steps/02-plugins.sh`.
- [ ] **Step 5: Run tests, shellcheck** — Expected: PASS.
- [ ] **Step 6: Commit** `feat: step 02 plugin installs`.

---

### Task 7: Steps 03 and 04 — graphify (with uv) and qmd CLI

**Files:**
- Create: `steps/03-graphify.sh`, `steps/04-qmd-cli.sh`, `tests/test_step03_04.sh`

**Interfaces:**
- `03`: `ensure_uv()` order: `have uv` → `pip install --user uv` (try `pip3` then `pip`) → `curl -LsSf --max-time 120 https://astral.sh/uv/install.sh | sh`; then `ensure_path`. If `uv` is still missing → return 1, `reason: could not install uv`. Then `uv tool install graphifyy` (skip with `already installed` if `have graphify`), then `graphify install`; first check what `graphify install` changes (`graphify install --help`) and log it. Test hooks: env `UV_BIN`, `PIP_BIN`, and a fake `graphify`/`uv` on a sandbox `PATH`.
- `04`: if `have qmd` → OK `already installed`. Else `npm install -g @tobilu/qmd` if npm exists; else `bun install -g @tobilu/qmd`; neither → return 1, `reason: need npm (Node 22+) or bun`. Node older than 22 → return 1 with the version in `reason:`. After install, verify `qmd --version`. Never install Node.

- [ ] **Step 1: Write failing tests** with fake binaries on a sandbox `PATH` (fake `uv`, `pip`, `npm`, `graphify`, `qmd` as small scripts that log their args): uv present → no pip call; uv absent and fake pip succeeds → pip called with `--user uv`; pip fails → astral installer path attempted (fake `curl` via `file://` URL override env `UV_INSTALL_URL`); all fail → `reason: could not install uv`; graphify already present → no `uv tool install`; `04` with no npm and no bun → non-zero and `need npm`; `04` with fake npm → `npm install -g @tobilu/qmd` observed; `04` with `node` reporting v20 → non-zero and `v20` in reason (fake `node`).
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** both steps. Use `curl --max-time` on every download (Review Focus 4).
- [ ] **Step 4: Run tests, shellcheck** — Expected: PASS.
- [ ] **Step 5: Commit** `feat: steps 03/04 graphify with uv, qmd cli`.

---

### Task 8: Optional step 90 — headroom

**Files:**
- Create: `steps/90-headroom.sh`, `tests/test_step90.sh`

**Interfaces:**
- `step_run`: `claude plugin marketplace add chopratejas/headroom`, then `claude plugin install headroom@headroom-marketplace`. Same `CLAUDE_BIN` hook as Task 6. Before coding, read `https://raw.githubusercontent.com/chopratejas/headroom/main/README.md` for extra install needs (the `headroom-ai` PyPI/npm package, proxy). Implement only what installation needs. Do NOT run `headroom wrap claude`. Log one line telling the owner how to enable it by hand.

- [ ] **Step 1: Write failing tests** with fake `CLAUDE_BIN`: step makes both calls and returns 0; master run without `--with-headroom` reports SKIPPED (covered in Task 2, re-assert with the real steps dir); fake failure → non-zero with `reason:`.
- [ ] **Step 2: Run** — FAIL. **Step 3: Implement.** **Step 4: Run tests, shellcheck** — PASS.
- [ ] **Step 5: Commit** `feat: optional step 90 headroom`.

---

### Task 9: README, end-to-end sandbox run, final checks

**Files:**
- Create: `README.md`, `tests/test_e2e.sh`

**Interfaces:**
- README sections: what it installs (table of the 7 steps + optional), usage and flags, "after install" (`source ~/.bashrc`, log in with `claude`, build graphs with `/graphify`, add qmd collections with `qmd collection add <path> --name X --mask "**/*.{md,txt}"`), qmd limits (text only; PDF and DOCX not searchable; HTML indexes raw markup — noisy), the style-drift note, how to run tests, MIT license line.
- `tests/test_e2e.sh`: sandbox `HOME`; fake `claude`, `uv`, `npm`, `graphify`, `qmd`, `pip` on `PATH`; run `bash install.sh` for real; assert exit `0`, summary lists all 7 steps OK and headroom SKIPPED, `~/.claude/settings.json` has the three keys, style file present, CLAUDE.md block present; run again and assert exit `0` and no new `.bak.*` files for unchanged files; run with `--dry-run` in a fresh sandbox and assert no files were created under `$HOME/.claude`.

- [ ] **Step 1: Write the e2e test; run** — Expected: FAIL until README/wiring complete.
- [ ] **Step 2: Fix any wiring gaps found; write the README.**
- [ ] **Step 3: Run** `bash tests/run.sh` and `shellcheck install.sh lib/*.sh steps/*.sh tests/*.sh` — Expected: all PASS, clean.
- [ ] **Step 4: Real-machine smoke test (owner's laptop, safe parts only):** `bash install.sh --dry-run` and read the output; no file under real `~/.claude` may change (`git`-less check: `find ~/.claude -newer README.md -type f | head` shows nothing new from this run).
- [ ] **Step 5: Commit** `docs: README and e2e test`.

---

## Self-Review
- **Spec coverage:** goals 1–4 → Tasks 1–2, 5–6; steps 01 → T3; 02 → T6; 03 → T7; 04 → T7; 05, 06 → T4; 07 → T5; headroom → T8; flags → T2; style text → T4; qmd comment → T5; README, MIT, testing → T1, T9. Non-goals respected: no auth, no caveman, no collections.
- **Type consistency:** `step_run` return codes (0/3/other), `reason:` log prefix, `CLAUDE_BIN` hook, `backup_file`, `run`, `ensure_path` names match across tasks.
- **Review Focus:** items 1–5 map to Tasks 3, 4, 3+5, 3+6+7, 6+7.
- **Spec change introduced by the plan (my call):** step 06 uses `python3` only, no `jq` (spec said jq with python fallback). One code path is simpler to test.
