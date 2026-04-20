# FAHHHH

"But Joseph," I hear you ask, how can one's programming session feel more consequential? I present FAHHHH. Plays the **FAHHHH** sound whenever Claude Code or Codex runs a test or linter that fails.

Works with both agents side-by-side — the installer auto-detects whichever of `~/.claude/` and `~/.codex/` exists and wires up each one.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/jsphbtst/claude-code-fahhh/main/install.sh | bash
```

Restart any active Claude Code / Codex sessions after installing.

## What it detects

**Test runners** — jest, vitest, mocha, pytest, cargo test, go test, rspec, phpunit, bun test, deno test, and more

**Linters & type checkers** — eslint, tsc, pylint, mypy, ruff, pyright, flake8, biome, clippy, rubocop, shellcheck, and more

**Script aliases** — `npm run test`, `npm run lint`, `pnpm test`, `yarn lint`, `make test`, `make lint`, `uv run pytest`, etc.

## Requirements

- macOS (uses `afplay` for audio playback)
- `jq` (for install script)
- Claude Code and/or Codex

## Codex: experimental hooks flag

Codex's lifecycle hooks are an experimental feature and off by default. If the installer detects Codex, it prompts before adding the following to `~/.codex/config.toml`:

```toml
[features]
codex_hooks = true
```

Decline the prompt to skip the Codex install entirely — Claude Code will still be wired up if it's present. The uninstaller leaves this flag in place, since you may have other Codex hooks that rely on it.

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/jsphbtst/claude-code-fahhh/main/uninstall.sh | bash
```

## How it works

Uses each agent's native hooks system.

- **Claude Code** — `PostToolUse` + `PostToolUseFailure` events on the `Bash` tool, configured via `~/.claude/settings.json`.
- **Codex** — `PostToolUse` event with a `Bash` matcher, configured via `~/.codex/hooks.json`. Codex's payload doesn't include a separate exit code, so failure is inferred by grepping the command output for common failure markers.

Both wrappers share a tiny helper script that holds the test/lint regex and the `afplay` call, so the detection logic stays in one place.

## Contributing

Not accepting contributions — but fork away. It's the age of custom software. Take it, make it yours, swap the sound, add new patterns, go wild.

## License

MIT
