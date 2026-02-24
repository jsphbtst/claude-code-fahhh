#!/bin/bash
set -euo pipefail

HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS_FILE="$HOME/.claude/settings.json"

info() { printf "\033[1;34m%s\033[0m\n" "$1"; }
success() { printf "\033[1;32m%s\033[0m\n" "$1"; }

main() {
  echo ""
  echo "  Uninstalling FAHHHH Sound..."
  echo ""

  # Remove hook files
  if [[ -f "$HOOKS_DIR/fah-sound.sh" ]]; then
    rm "$HOOKS_DIR/fah-sound.sh"
    info "Removed $HOOKS_DIR/fah-sound.sh"
  fi
  if [[ -f "$HOOKS_DIR/fahhhh.mp3" ]]; then
    rm "$HOOKS_DIR/fahhhh.mp3"
    info "Removed $HOOKS_DIR/fahhhh.mp3"
  fi

  # Remove hook entries from settings
  if [[ -f "$SETTINGS_FILE" ]] && command -v jq >/dev/null 2>&1; then
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"

    # Filter out any hook entries that reference fah-sound.sh
    jq '
      if .hooks then
        .hooks |= with_entries(
          .value |= map(select(
            .hooks | all(.command | test("fah-sound") | not)
          ))
          | if .value == [] then empty else . end
        )
        | if .hooks == {} then del(.hooks) else . end
      else .
      end
    ' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

    info "Removed hook config from settings.json"
  fi

  echo ""
  success "Uninstalled. Restart any active Claude Code sessions."
}

main
