#!/bin/bash
# Shared pattern matcher + sound trigger for fah-sound wrappers.
# Sourced by fah-sound-claude.sh and fah-sound-codex.sh.
#
# Usage: after sourcing, call `fah_maybe_play "$COMMAND" "$IS_FAILURE" "$SOUND_PATH"`.
#   - COMMAND: the shell command string the agent ran
#   - IS_FAILURE: "true" if the caller already determined the command failed
#   - SOUND_PATH: absolute path to fahhhh.mp3

FAH_TEST_PATTERN='(^|\s|/)(jest|vitest|mocha|pytest|py\.test|phpunit|rspec|cargo\s+test|go\s+test|dotnet\s+test|swift\s+test|mix\s+test|bun\s+test|deno\s+test)(\s|$)|npm\s+(run\s+)?test|pnpm\s+(run\s+)?test|yarn\s+(run\s+)?test|npx\s+(jest|vitest|mocha)|python\s+-m\s+(pytest|unittest)|uv\s+run\s+(pytest|python\s+-m\s+(pytest|unittest))|make\s+test'

FAH_LINT_PATTERN='(^|\s|/)(eslint|prettier|biome|oxlint|stylelint|tsc|pylint|flake8|ruff|mypy|pyright|black|isort|rubocop|clippy|golangci-lint|swiftlint|ktlint|shellcheck|hadolint)(\s|$)|cargo\s+clippy|npm\s+(run\s+)?lint|pnpm\s+(run\s+)?lint|yarn\s+(run\s+)?lint|npx\s+(eslint|prettier|biome|tsc|oxlint)|python\s+-m\s+(pylint|flake8|mypy|pyright|black|isort)|uv\s+run\s+(ruff|pylint|flake8|mypy|pyright|black|isort)|make\s+lint'

fah_maybe_play() {
  local command="$1"
  local is_failure="$2"
  local sound_path="$3"

  [[ -z "$command" ]] && return 0
  [[ "$is_failure" != "true" ]] && return 0

  if echo "$command" | grep -qEi "$FAH_TEST_PATTERN|$FAH_LINT_PATTERN"; then
    afplay "$sound_path" &
  fi
}
