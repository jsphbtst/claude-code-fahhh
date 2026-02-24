#!/bin/bash
# Plays the FAHHHH sound when a test or lint command fails.
# Triggered by Claude Code PostToolUse + PostToolUseFailure hooks on Bash tool calls.

INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[[ -z "$COMMAND" ]] && exit 0

# Determine if this is a failure
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

[[ "$IS_FAILURE" != "true" ]] && exit 0

# Test runners
TEST_PATTERN='(^|\s|/)(jest|vitest|mocha|pytest|py\.test|phpunit|rspec|cargo\s+test|go\s+test|dotnet\s+test|swift\s+test|mix\s+test|bun\s+test|deno\s+test)(\s|$)|npm\s+(run\s+)?test|pnpm\s+(run\s+)?test|yarn\s+(run\s+)?test|npx\s+(jest|vitest|mocha)|python\s+-m\s+(pytest|unittest)|uv\s+run\s+(pytest|python\s+-m\s+(pytest|unittest))|make\s+test'

# Linters, formatters, type checkers
LINT_PATTERN='(^|\s|/)(eslint|prettier|biome|oxlint|stylelint|tsc|pylint|flake8|ruff|mypy|pyright|black|isort|rubocop|clippy|golangci-lint|swiftlint|ktlint|shellcheck|hadolint)(\s|$)|cargo\s+clippy|npm\s+(run\s+)?lint|pnpm\s+(run\s+)?lint|yarn\s+(run\s+)?lint|npx\s+(eslint|prettier|biome|tsc|oxlint)|python\s+-m\s+(pylint|flake8|mypy|pyright|black|isort)|uv\s+run\s+(ruff|pylint|flake8|mypy|pyright|black|isort)|make\s+lint'

if echo "$COMMAND" | grep -qEi "$TEST_PATTERN|$LINT_PATTERN"; then
  afplay "$HOME/.claude/hooks/fahhhh.mp3" &
fi

exit 0
