#!/bin/bash
# Claude Code wrapper: plays FAHHHH when a test/lint command fails.
# Triggered by PostToolUse + PostToolUseFailure hooks on the Bash tool.

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/fah-detect.sh
source "$HOOK_DIR/lib/fah-detect.sh"

INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[[ -z "$COMMAND" ]] && exit 0

IS_FAILURE=false
if [[ "$EVENT" == "PostToolUseFailure" ]]; then
  IS_FAILURE=true
elif [[ "$EVENT" == "PostToolUse" ]]; then
  STDERR=$(echo "$INPUT" | jq -r '.tool_response.stderr // empty')
  STDOUT=$(echo "$INPUT" | jq -r '.tool_response.stdout // empty')
  if [[ -n "$STDERR" ]] && echo "$STDOUT" | grep -qEi '(FAIL|ERROR|error:|failed|exit code [1-9])'; then
    IS_FAILURE=true
  fi
fi

fah_maybe_play "$COMMAND" "$IS_FAILURE" "$HOOK_DIR/fahhhh.mp3"

exit 0
