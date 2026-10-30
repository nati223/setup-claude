#!/usr/bin/env bash
# Step 02: install plugins from Claude plugin marketplaces. Each plugin is independent.
# CLI used (checked with `claude plugin --help`): marketplace list|add <repo>, list, install <plugin@marketplace>.
# shellcheck source=lib/plugins.sh
source "$REPO_DIR/lib/plugins.sh"

PLUGINS=(
  "anthropics/claude-plugins-official superpowers@claude-plugins-official"
  "tobi/qmd qmd@qmd"
  "forrestchang/andrej-karpathy-skills andrej-karpathy-skills@karpathy-skills"
  "392fyc/claude-handoff claude-handoff@claude-handoff"
)

step_run() {
  local p repo id failed=()
  ensure_path
  have "${CLAUDE_BIN:-claude}" || { log "reason: claude not found (run step 01)"; return 1; }
  for p in "${PLUGINS[@]}"; do
    read -r repo id <<< "$p"
    plugin_install "$repo" "$id" || failed+=("$id")
  done
  if [ ${#failed[@]} -eq 0 ]; then log "reason: ${#PLUGINS[@]} plugins ok"; return 0; fi
  log "reason: failed: ${failed[*]}"
  return 1
}
