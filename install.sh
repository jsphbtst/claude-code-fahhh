#!/bin/bash
set -euo pipefail

REPO="jsphbtst/claude-code-fahhh"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

# For local testing: FAH_SOURCE_DIR=/path/to/repo ./install.sh
# When set, files are copied from that directory instead of fetched over HTTP.
FAH_SOURCE_DIR="${FAH_SOURCE_DIR:-}"

CLAUDE_DIR="$HOME/.claude"
CLAUDE_HOOKS_DIR="$CLAUDE_DIR/hooks"
CLAUDE_SETTINGS="$CLAUDE_DIR/settings.json"

CODEX_DIR="$HOME/.codex"
CODEX_HOOKS_DIR="$CODEX_DIR/hooks"
CODEX_HOOKS_FILE="$CODEX_DIR/hooks.json"
CODEX_CONFIG="$CODEX_DIR/config.toml"

# --- helpers ---

info() { printf "\033[1;34m%s\033[0m\n" "$1"; }
success() { printf "\033[1;32m%s\033[0m\n" "$1"; }
warn() { printf "\033[1;33m%s\033[0m\n" "$1"; }
error() { printf "\033[1;31mError: %s\033[0m\n" "$1" >&2; exit 1; }

check_deps() {
  local required=(jq)
  [[ -z "$FAH_SOURCE_DIR" ]] && required+=(curl)
  for cmd in "${required[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || error "'$cmd' is required but not installed."
  done

  if [[ "$(uname)" == "Darwin" ]]; then
    command -v afplay >/dev/null 2>&1 || error "'afplay' not found. This tool currently only supports macOS."
  else
    error "fah-sound currently only supports macOS (requires afplay)."
  fi

  if [[ -n "$FAH_SOURCE_DIR" ]]; then
    [[ -d "$FAH_SOURCE_DIR/hooks" ]] || error "FAH_SOURCE_DIR='$FAH_SOURCE_DIR' does not contain a hooks/ directory."
  fi
}

# Fetches a repo-relative path to a destination. Uses FAH_SOURCE_DIR if set
# (local copy), otherwise curls from BASE_URL.
fetch_file() {
  local rel="$1" dest="$2"
  if [[ -n "$FAH_SOURCE_DIR" ]]; then
    cp "$FAH_SOURCE_DIR/$rel" "$dest"
  else
    curl -fsSL "$BASE_URL/$rel" -o "$dest"
  fi
}

download_shared() {
  local hooks_dir="$1"
  mkdir -p "$hooks_dir/lib"
  fetch_file "hooks/fahhhh.mp3" "$hooks_dir/fahhhh.mp3"
  fetch_file "hooks/lib/fah-detect.sh" "$hooks_dir/lib/fah-detect.sh"
  chmod +x "$hooks_dir/lib/fah-detect.sh"
}

# --- Claude Code ---

install_claude() {
  info "Installing for Claude Code..."

  download_shared "$CLAUDE_HOOKS_DIR"
  fetch_file "hooks/fah-sound-claude.sh" "$CLAUDE_HOOKS_DIR/fah-sound-claude.sh"
  chmod +x "$CLAUDE_HOOKS_DIR/fah-sound-claude.sh"

  # Clean up legacy single-script install from earlier versions.
  [[ -f "$CLAUDE_HOOKS_DIR/fah-sound.sh" ]] && rm "$CLAUDE_HOOKS_DIR/fah-sound.sh"

  local hook_config
  hook_config=$(cat <<JSON
{
  "PostToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        { "type": "command", "command": "$CLAUDE_HOOKS_DIR/fah-sound-claude.sh" }
      ]
    }
  ],
  "PostToolUseFailure": [
    {
      "matcher": "Bash",
      "hooks": [
        { "type": "command", "command": "$CLAUDE_HOOKS_DIR/fah-sound-claude.sh" }
      ]
    }
  ]
}
JSON
)

  if [[ ! -f "$CLAUDE_SETTINGS" ]]; then
    mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
    echo '{}' > "$CLAUDE_SETTINGS"
  fi

  cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.bak"

  # Strip any existing fah-sound entries (covers re-installs and legacy names),
  # then deep-merge the fresh entries in.
  jq --argjson new "$hook_config" '
    .hooks = (.hooks // {})
    | .hooks |= with_entries(
        .value |= map(
          .hooks |= map(select(.command | test("fah-sound") | not))
        )
        | .value |= map(select(.hooks | length > 0))
      )
    | .hooks |= (
        . as $cur
        | $new | to_entries | reduce .[] as $e ($cur;
            if .[$e.key] then .[$e.key] += $e.value
            else .[$e.key] = $e.value end
          )
      )
  ' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"

  success "  ✓ Claude Code configured ($CLAUDE_SETTINGS)"
}

# --- Codex ---

# Return codes: 0 = already enabled, 1 = we just enabled it, 2 = key present but not true (user intervention needed)
check_codex_hooks_flag() {
  [[ ! -f "$CODEX_CONFIG" ]] && return 1
  if grep -qE '^[[:space:]]*codex_hooks[[:space:]]*=[[:space:]]*true[[:space:]]*$' "$CODEX_CONFIG"; then
    return 0
  fi
  if grep -qE '^[[:space:]]*codex_hooks[[:space:]]*=' "$CODEX_CONFIG"; then
    return 2
  fi
  return 1
}

enable_codex_hooks_flag() {
  mkdir -p "$(dirname "$CODEX_CONFIG")"

  if [[ ! -f "$CODEX_CONFIG" ]]; then
    printf "[features]\ncodex_hooks = true\n" > "$CODEX_CONFIG"
    return
  fi

  cp "$CODEX_CONFIG" "$CODEX_CONFIG.bak"

  if grep -qE '^[[:space:]]*\[features\][[:space:]]*$' "$CODEX_CONFIG"; then
    # Insert codex_hooks = true on the line immediately after [features].
    awk '
      BEGIN { done = 0 }
      /^[[:space:]]*\[features\][[:space:]]*$/ && !done {
        print
        print "codex_hooks = true"
        done = 1
        next
      }
      { print }
    ' "$CODEX_CONFIG" > "$CODEX_CONFIG.tmp" && mv "$CODEX_CONFIG.tmp" "$CODEX_CONFIG"
  else
    # No [features] section yet; append one.
    [[ -s "$CODEX_CONFIG" ]] && [[ "$(tail -c 1 "$CODEX_CONFIG" | wc -l | tr -d ' ')" -eq 0 ]] && echo "" >> "$CODEX_CONFIG"
    printf "\n[features]\ncodex_hooks = true\n" >> "$CODEX_CONFIG"
  fi
}

install_codex() {
  info "Installing for Codex..."

  local flag_status
  check_codex_hooks_flag && flag_status=0 || flag_status=$?

  if [[ "$flag_status" == "2" ]]; then
    warn "  Your $CODEX_CONFIG already sets codex_hooks to a value other than true."
    warn "  Update it manually to 'codex_hooks = true' under [features] and re-run."
    return 1
  fi

  if [[ "$flag_status" == "1" ]]; then
    echo ""
    info "  Codex hooks are an experimental feature, off by default."
    info "  To install, this line will be added to $CODEX_CONFIG:"
    echo ""
    echo "    [features]"
    echo "    codex_hooks = true"
    echo ""
    printf "  Enable it now? [Y/n] "
    read -r reply </dev/tty
    reply=${reply:-Y}
    if [[ ! "$reply" =~ ^[Yy] ]]; then
      warn "  Skipping Codex install."
      return 1
    fi
    enable_codex_hooks_flag
    success "  ✓ Enabled codex_hooks in $CODEX_CONFIG"
  fi

  download_shared "$CODEX_HOOKS_DIR"
  fetch_file "hooks/fah-sound-codex.sh" "$CODEX_HOOKS_DIR/fah-sound-codex.sh"
  chmod +x "$CODEX_HOOKS_DIR/fah-sound-codex.sh"

  local hook_config
  hook_config=$(cat <<JSON
{
  "PostToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        { "type": "command", "command": "$CODEX_HOOKS_DIR/fah-sound-codex.sh" }
      ]
    }
  ]
}
JSON
)

  if [[ ! -f "$CODEX_HOOKS_FILE" ]]; then
    echo '{}' > "$CODEX_HOOKS_FILE"
  fi

  cp "$CODEX_HOOKS_FILE" "$CODEX_HOOKS_FILE.bak"

  jq --argjson new "$hook_config" '
    .hooks = (.hooks // {})
    | .hooks |= with_entries(
        .value |= map(
          .hooks |= map(select(.command | test("fah-sound") | not))
        )
        | .value |= map(select(.hooks | length > 0))
      )
    | .hooks |= (
        . as $cur
        | $new | to_entries | reduce .[] as $e ($cur;
            if .[$e.key] then .[$e.key] += $e.value
            else .[$e.key] = $e.value end
          )
      )
  ' "$CODEX_HOOKS_FILE" > "$CODEX_HOOKS_FILE.tmp" && mv "$CODEX_HOOKS_FILE.tmp" "$CODEX_HOOKS_FILE"

  success "  ✓ Codex configured ($CODEX_HOOKS_FILE)"
}

# --- main ---

main() {
  echo ""
  echo "  FAHHHH Sound for Claude Code + Codex"
  echo "  Plays a sound when tests or linters fail."
  echo ""

  check_deps

  local has_claude=false has_codex=false
  [[ -d "$CLAUDE_DIR" ]] && has_claude=true
  [[ -d "$CODEX_DIR" ]] && has_codex=true

  if ! $has_claude && ! $has_codex; then
    error "Neither ~/.claude nor ~/.codex exists. Install Claude Code and/or Codex first."
  fi

  info "Detected:"
  $has_claude && echo "  • Claude Code ($CLAUDE_DIR)"
  $has_codex && echo "  • Codex ($CODEX_DIR)"
  echo ""

  if $has_claude; then
    install_claude
  fi

  if $has_codex; then
    install_codex || true
  fi

  echo ""
  success "Done. Restart any active sessions to activate."
  success "When a test or linter fails, you'll hear it."
  echo ""
}

main
