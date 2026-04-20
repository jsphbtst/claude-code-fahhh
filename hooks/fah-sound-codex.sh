#!/bin/bash
# Codex wrapper: plays FAHHHH when a test/lint command fails.
# Triggered by the PostToolUse hook in ~/.codex/hooks.json (matcher: "Bash").
#
# Codex's PostToolUse payload puts the full truncated command output into
# tool_response as a single JSON string — there is no separate exit_code,
# stdout, or stderr field. We infer failure by grepping that string for
# common failure markers.

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/fah-detect.sh
source "$HOOK_DIR/lib/fah-detect.sh"

INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[[ "$EVENT" != "PostToolUse" ]] && exit 0
[[ "$TOOL_NAME" != "Bash" ]] && exit 0
[[ -z "$COMMAND" ]] && exit 0

# tool_response is serialized as a JSON string; decode it to raw text for grepping.
OUTPUT=$(echo "$INPUT" | jq -r 'if (.tool_response | type) == "string" then .tool_response else (.tool_response | tostring) end // empty')

IS_FAILURE=false
if echo "$OUTPUT" | grep -qEi '(FAIL|ERROR|error:|failed|exit code [1-9]|command timed out)'; then
  IS_FAILURE=true
fi

fah_maybe_play "$COMMAND" "$IS_FAILURE" "$HOOK_DIR/fahhhh.mp3"

exit 0
