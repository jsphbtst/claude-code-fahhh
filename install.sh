#!/bin/bash
set -euo pipefail

REPO="jsphbtst/claude-code-fahhh"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS_FILE="$HOME/.claude/settings.json"

HOOK_CONFIG='{
  "PostToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "%HOOKS_DIR%/fah-sound.sh"
        }
      ]
    }
  ],
  "PostToolUseFailure": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "%HOOKS_DIR%/fah-sound.sh"
        }
      ]
    }
  ]
}'

# --- helpers ---

info() { printf "\033[1;34m%s\033[0m\n" "$1"; }
success() { printf "\033[1;32m%s\033[0m\n" "$1"; }
error() { printf "\033[1;31mError: %s\033[0m\n" "$1" >&2; exit 1; }

check_deps() {
  for cmd in curl jq; do
    command -v "$cmd" >/dev/null 2>&1 || error "'$cmd' is required but not installed."
  done

  if [[ "$(uname)" == "Darwin" ]]; then
    command -v afplay >/dev/null 2>&1 || error "'afplay' not found. This tool currently only supports macOS."
  else
    error "fah-sound currently only supports macOS (requires afplay)."
  fi
}

# --- install steps ---

download_files() {
  info "Downloading hook files..."
  mkdir -p "$HOOKS_DIR"
  curl -fsSL "$BASE_URL/hooks/fah-sound.sh" -o "$HOOKS_DIR/fah-sound.sh"
  curl -fsSL "$BASE_URL/hooks/fahhhh.mp3" -o "$HOOKS_DIR/fahhhh.mp3"
  chmod +x "$HOOKS_DIR/fah-sound.sh"
}

configure_hooks() {
  info "Configuring Claude Code hooks..."

  # Inject the actual hooks dir path
  local hook_json
  hook_json=$(echo "$HOOK_CONFIG" | sed "s|%HOOKS_DIR%|$HOOKS_DIR|g")

  # Create settings.json if it doesn't exist
  if [[ ! -f "$SETTINGS_FILE" ]]; then
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    echo '{}' > "$SETTINGS_FILE"
  fi

  # Backup
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"

  # Merge hooks into settings
  local current_hooks new_hooks merged
  current_hooks=$(jq '.hooks // {}' "$SETTINGS_FILE")
  new_hooks="$hook_json"

  # Deep merge: append our hook entries to any existing PostToolUse/PostToolUseFailure arrays
  merged=$(jq -n \
    --argjson current "$current_hooks" \
    --argjson new "$new_hooks" \
    '$current as $c | $new | to_entries | reduce .[] as $e ($c;
      if .[$e.key] then .[$e.key] += $e.value
      else .[$e.key] = $e.value end
    )'
  )

  # Write back
  jq --argjson hooks "$merged" '.hooks = $hooks' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" \
    && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
}

# --- main ---

main() {
  echo ""
  echo "  FAHHHH Sound for Claude Code"
  echo "  Plays a sound when tests or linters fail."
  echo ""

  check_deps
  download_files
  configure_hooks

  echo ""
  success "Installed! Restart any active Claude Code sessions to activate."
  success "When Claude runs a test or linter that fails, you'll hear it."
  echo ""
  info "Files installed:"
  echo "  $HOOKS_DIR/fah-sound.sh"
  echo "  $HOOKS_DIR/fahhhh.mp3"
  echo ""
  info "Settings backup: $SETTINGS_FILE.bak"
}

main
