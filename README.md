# AI Coderz

AI Coderz is a unified Bash launcher that runs a plan-and-implement loop using any supported coder and reviewer CLI pair:

- `bin/aicoderz` accepts `--coder` and `--reviewer` flags; accepted values are `claude`, `codex`, and `cursor`, optionally with a model suffix: `cli/model`.

- Author: Mike Lopez <e@mikelopez.com>
- Copyright (C) 2026 Mike Lopez <e@mikelopez.com>

## What It Does

`aicoderz` follows this control flow:

1. Accept `--branch <name>` or `--current-branch` plus a prompt.
2. Switch to the named branch when it exists, create it when it does not, or use the current branch when `--current-branch` is passed.
3. Run the coder CLI with its workflow skill prefix: `/plan-it` for Claude and Cursor, `$plan-it` for Codex.
4. Run the reviewer CLI on the generated plan.
5. Loop on the coder CLI with `/plan-update` or `$plan-update` plus re-review until `.ai/branches/<branch-slug>/plan-review.md` contains `ALL GOOD`.
6. Run the coder CLI with `/code-it` or `$code-it`.
7. Run the reviewer CLI on the implementation.
8. Loop on the coder CLI with `/code-fix` or `$code-fix` plus re-review until `.ai/branches/<branch-slug>/code-review.md` contains `ALL GOOD`.
9. Stop early if required CLIs are missing from `PATH`.

The retry loop is controlled by:

- `MAX_TRIES` with a default of `20`
- `SLEEP_SECS` with a default of `0.2`

## CLI Options

| Flag | Short | Required | Accepted values |
|---|---|---|---|
| `--coder` | `-C` | Yes | `cli` or `cli/model`; CLIs: `claude`, `codex`, `cursor` |
| `--reviewer` | `-R` | Yes | `cli` or `cli/model`; CLIs: `claude`, `codex`, `cursor`; must differ from `--coder` by CLI or model |
| `--branch` | `-B` | Unless `--current-branch` | Branch name to switch to or create |
| `--current-branch` | | Unless `--branch` | Use the current git branch |

The `cli/model` format passes `--model <model>` to the chosen CLI. When no model is specified the
CLI uses its own default. For `cursor`, the built-in default is `gpt-5.3-codex-high`.

## Requirements

Common requirements:

- Linux
- `bash`
- `git`
- [GitHub CLI (`gh`)](https://cli.github.com/)

The CLIs required depend on the values you pass to `--coder` and `--reviewer`:

- `claude`: [Claude CLI](https://docs.anthropic.com/en/docs/claude-code)
- `codex`: [Codex CLI](https://developers.openai.com/codex/cli/)
- `cursor`: `cursor-agent`

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/easterncoder/claudex-coder.git
cd claudex-coder
```

### 2. Install the launcher

```bash
sudo install -m 0755 bin/aicoderz /usr/local/bin/aicoderz
```

If you prefer to run from the repo directly:

```bash
chmod +x bin/aicoderz
```

#### Legacy launchers

The original single-CLI launchers are still available if you need them:

```bash
sudo install -m 0755 bin/claudex-coder /usr/local/bin/claudex-coder
sudo install -m 0755 bin/claursor-coder /usr/local/bin/claursor-coder
```

### 3. Install the shared skills

This repository ships the workflow skills in `skills/`.

Install them for Claude (required when `--coder claude` or `--reviewer claude`):

```bash
mkdir -p "$HOME/.claude/skills"
cp -R skills/. "$HOME/.claude/skills/"
```

If you pass `--coder codex` or `--reviewer codex`, also install for Codex:

```bash
mkdir -p "$HOME/.codex/skills"
cp -R skills/. "$HOME/.codex/skills/"
```

Codex invokes these skills with a `$` prefix:

- `$plan-it`
- `$plan-review`
- `$plan-update`
- `$code-it`
- `$code-review`
- `$code-fix`

If you pass `--coder cursor` or `--reviewer cursor`, make sure your `cursor-agent` setup exposes the same workflow commands from this repository:

- `/plan-it`
- `/plan-review`
- `/plan-update`
- `/code-it`
- `/code-review`
- `/code-fix`

## Setup Check

Verify the always-required CLIs:

```bash
git --version
gh --version
```

Verify each CLI you plan to pass to `--coder` or `--reviewer`:

```bash
claude --version
```

```bash
codex --version
```

```bash
cursor-agent --version
```

## Usage

```bash
aicoderz --coder <cli[/model]> --reviewer <cli[/model]> (--branch <name> | --current-branch) <prompt...>
```

Examples:

```bash
aicoderz --coder claude --reviewer codex --branch feature/api-caching "add caching to API responses"
aicoderz -C claude -R cursor -B feature/api-caching "add caching to API responses"
aicoderz --coder claude --reviewer codex --current-branch "fix the login bug"
aicoderz --coder cursor/composer-1 --reviewer claude/claude-opus-4-6 --current-branch "add model routing"
aicoderz --coder claude/claude-sonnet-4-6 --reviewer claude/claude-opus-4-6 --current-branch "add feature"
```

### Legacy Launchers

`claudex-coder` and `claursor-coder` use positional arguments:

```bash
claudex-coder "" "add caching to API responses"
claudex-coder feature/api-caching "add caching to API responses"
```

```bash
claursor-coder "" "add caching to API responses"
claursor-coder feature/api-caching "add caching to API responses"
```

## License

GPL-2.0

## Forking and GPL-2.0 Compliance

If you fork or redistribute this project, GPL-2.0 requires that you:

- Keep copyright and license notices in place, including original author attribution.
- Include a copy of the GPL-2.0 license with your distribution.
- Mark modified files with clear change notices and dates.
- License derivative works under GPL-2.0 when distributed.
- Provide complete corresponding source code when distributing binaries or executables.
