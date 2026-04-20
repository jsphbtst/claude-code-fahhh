#!/bin/bash
set -euo pipefail

CLAUDE_HOOKS_DIR="$HOME/.claude/hooks"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

CODEX_HOOKS_DIR="$HOME/.codex/hooks"
CODEX_HOOKS_FILE="$HOME/.codex/hooks.json"

info() { printf "\033[1;34m%s\033[0m\n" "$1"; }
success() { printf "\033[1;32m%s\033[0m\n" "$1"; }

# Strips any hook entries whose command references "fah-sound" from a Claude-
# Code-style hooks JSON file ({ "hooks": { Event: [ { matcher, hooks: [...] } ] } }).
strip_hook_entries() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  command -v jq >/dev/null 2>&1 || return 0

  cp "$file" "$file.bak"

  jq '
    if .hooks then
      .hooks |= with_entries(
        .value |= map(
          .hooks |= map(select(.command | test("fah-sound") | not))
        )
        | .value |= map(select(.hooks | length > 0))
        | if .value == [] then empty else . end
      )
      | if .hooks == {} then del(.hooks) else . end
    else .
    end
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

remove_hook_files() {
  local dir="$1"
  for f in fah-sound.sh fah-sound-claude.sh fah-sound-codex.sh fahhhh.mp3 lib/fah-detect.sh; do
    if [[ -f "$dir/$f" ]]; then
      rm "$dir/$f"
      info "Removed $dir/$f"
    fi
  done
  # Remove empty lib dir if we created it.
  [[ -d "$dir/lib" ]] && rmdir "$dir/lib" 2>/dev/null || true
}

main() {
  echo ""
  echo "  Uninstalling FAHHHH Sound..."
  echo ""

  if [[ -d "$CLAUDE_HOOKS_DIR" ]]; then
    remove_hook_files "$CLAUDE_HOOKS_DIR"
    strip_hook_entries "$CLAUDE_SETTINGS"
    info "Cleaned Claude Code config"
  fi

  if [[ -d "$CODEX_HOOKS_DIR" ]]; then
    remove_hook_files "$CODEX_HOOKS_DIR"
    strip_hook_entries "$CODEX_HOOKS_FILE"
    info "Cleaned Codex config"
    info "Note: the [features] codex_hooks flag in ~/.codex/config.toml was left in place"
  fi

  echo ""
  success "Uninstalled. Restart any active sessions."
}

main
