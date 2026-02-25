# Claude Code FAHHHH

"But Joseph," I hear you ask, how can one's programming session feel more consequential? I present Claude Code FAHHHH. Plays the **FAHHHH** sound whenever Claude Code runs a test or linter that fails.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/jsphbtst/claude-code-fahhh/main/install.sh | bash
```

Restart any active Claude Code sessions after installing.

## What it detects

**Test runners** — jest, vitest, mocha, pytest, cargo test, go test, rspec, phpunit, bun test, deno test, and more

**Linters & type checkers** — eslint, tsc, pylint, mypy, ruff, pyright, flake8, biome, clippy, rubocop, shellcheck, and more

**Script aliases** — `npm run test`, `npm run lint`, `pnpm test`, `yarn lint`, `make test`, `make lint`, `uv run pytest`, etc.

## Requirements

- macOS (uses `afplay` for audio playback)
- `jq` (for install script)
- Claude Code

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/jsphbtst/claude-code-fahhh/main/uninstall.sh | bash
```

## How it works

Uses [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) — specifically `PostToolUse` and `PostToolUseFailure` events on the `Bash` tool. When Claude runs a command that matches a test/lint pattern and it fails, the hook plays the sound.

## Contributing

Not accepting contributions — but fork away. It's the age of custom software. Take it, make it yours, swap the sound, add new patterns, go wild.

## License

MIT
