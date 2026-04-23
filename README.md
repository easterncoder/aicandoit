# AI Can Do It

AI Can Do It is a unified Bash launcher that runs a plan-and-implement loop using any supported coder and reviewer CLI pair.

- `bin/aicandoit` accepts `--coder`, `--reviewer`, optional `--planner`, optional `--mode`, optional `--worktree`, and branch selection via `--branch`, `--current-branch`, or `--auto-branch`.
- Accepted CLIs are `claude`, `codex`, `cursor`, and `gemini`, optionally with a model suffix in `cli/model` form.

- Author: Mike Lopez <e@mikelopez.com>
- Copyright (C) 2026 Mike Lopez <e@mikelopez.com>

## What It Does

`aicandoit` follows this control flow:

1. Accept `--branch <name>`, `--current-branch`, or `--auto-branch` plus a prompt. When all three are omitted, infer current-branch mode when `.aicandoit/branches/<current-branch-slug>` already exists.
2. When `--auto-branch` is passed, assemble context in deterministic order: raw prompt text, GitHub issue references, GitHub PR references, then readable repo-local file snippets.
3. Ask the selected coder CLI for exactly one Conventional Commit style branch name before checkout or worktree setup. Existing local branch names still receive numeric suffixes such as `-2`.
4. Switch to the named branch when it exists, create it when it does not, or use the current branch when `--current-branch` is passed or inferred.
5. If `--worktree` is passed with `--branch` or `--auto-branch`, create or reuse a deterministic branch worktree under `<repo-root>/.aicandoit/branches/<branch-slug>/worktree` and run the workflow from that worktree.
6. Run the planner CLI with its workflow skill prefix: `/plan-it` for Claude, Cursor, and Gemini, `$plan-it` for Codex.
7. Run the reviewer CLI on the generated plan.
8. Loop on the planner CLI with `/plan-update` or `$plan-update` plus re-review until `.aicandoit/branches/<branch-slug>/plan-review.md` contains `ALL GOOD`.
9. Run the coder CLI with `/code-it` or `$code-it`.
10. Run the reviewer CLI on the implementation.
11. Loop on the coder CLI with `/code-fix` or `$code-fix` plus re-review until `.aicandoit/branches/<branch-slug>/code-review.md` contains `ALL GOOD`.
12. Stop early if required CLIs are missing from `PATH`.

The retry loop is controlled by:

- `MAX_TRIES` with a default of `20`
- `SLEEP_SECS` with a default of `0.2`

## CLI Options

| Flag | Short | Required | Accepted values |
|---|---|---|---|
| `--coder` | `-C` | Yes | `cli` or `cli/model`; CLIs: `claude`, `codex`, `cursor`, `gemini` |
| `--planner` | `-P` | No | `cli` or `cli/model`; CLIs: `claude`, `codex`, `cursor`, `gemini`; defaults to `--coder` |
| `--reviewer` | `-R` | Yes | `cli` or `cli/model`; CLIs: `claude`, `codex`, `cursor`, `gemini`; must differ from `--coder` and `--planner` by CLI or effective model |
| `--mode` | `-M` | No | `plan`, `plan-review`, `code`, or `code-review`; when omitted, the full workflow runs |
| `--worktree` | `-W` | No | Use a branch worktree instead of switching the source checkout |
| `--verbose` | | No | Flag only; when set, CLI tool output is shown with stderr merged into stdout |
| `--branch` | `-B` | Unless `--current-branch`, `--auto-branch`, or branch inference succeeds | Branch name to switch to or create |
| `--current-branch` | | Unless `--branch`, `--auto-branch`, or branch inference succeeds | Use the current git branch |
| `--auto-branch` | | No | Ask the selected coder CLI to generate a strict Conventional Commit style branch name |

The `cli/model` format passes `--model <model>` to the chosen CLI. When no model is specified the CLI uses its own default. For `cursor`, the built-in default is `gpt-5.3-codex-high`.
The `--mode` flag runs only the selected stage. `plan-review` requires an existing branch plan and creates `plan-review.md` on its first review pass when needed. `code-review` requires that you have already run the matching `code` stage on the same branch.
The `--verbose` flag shows CLI tool output and merges stderr into stdout so all tool output appears on stdout.
If `--branch`, `--current-branch`, and `--auto-branch` are all omitted, the launcher checks for `.aicandoit/branches/<current-branch-slug>`; if it does not exist, it fails with `error: pass --branch <name>, --current-branch, or --auto-branch`.
`--auto-branch` is mutually exclusive with `--branch` and `--current-branch`.
With `--worktree`, the launcher uses `<repo-root>/.aicandoit/branches/<branch-slug>/worktree`. `--worktree` does not support `--current-branch`.
In non-worktree mode, switching to a different branch or creating a new branch requires a clean source checkout. If the resolved target branch is already checked out, the launcher continues without blocking.
On successful `--worktree` runs, the launcher prints `AICANDOIT_WORKTREE_PATH=<absolute-path>` as a machine-readable handoff line.

## Worktree Wrapper

A child process cannot change your parent shell directory, so use a wrapper when you want to stay in the resolved worktree after a successful run:

```bash
aicandoit-worktree() {
  local output status handoff_path

  output="$(aicandoit "$@" 2>&1)"
  status=$?
  printf '%s\n' "$output"
  if [[ "$status" -ne 0 ]]; then
    return "$status"
  fi

  handoff_path="$(printf '%s\n' "$output" | sed -n 's/^AICANDOIT_WORKTREE_PATH=//p' | tail -n 1)"
  if [[ -n "$handoff_path" ]]; then
    cd "$handoff_path"
  fi
}
```

Example:

```bash
aicandoit-worktree --coder codex --reviewer claude --branch feature/worktree-smoke --worktree "run workflow in branch worktree"
pwd
```

## Auto Branch Rules

`--auto-branch` uses a strict AI preflight step:

1. Build branch-name context in this order: raw prompt text, issue references (`gh issue 24`, `issue 24`), PR references (`gh pr 7`, `pr 7`, `pull request 7`), then repo-local file snippets for explicitly mentioned paths.
2. For file snippets, only repo-local readable text files are included, repeated paths are deduplicated, and each snippet is capped at the first `AUTO_BRANCH_CONTEXT_MAX_LINES` lines or `AUTO_BRANCH_CONTEXT_MAX_BYTES` bytes, whichever comes first.
3. Call the selected coder CLI once and require exactly one output line in `<type>/<slug>` form.
4. Allowed types are `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, and `test`.
5. Invalid output fails fast with no deterministic fallback.
6. Existing local branch name collisions still receive numeric suffixes (`-2`, `-3`, and so on).

## Requirements

Common requirements:

- Linux
- `bash`
- `git`
- [GitHub CLI (`gh`)](https://cli.github.com/)

The CLIs required depend on the values you pass to `--coder`, `--planner`, and `--reviewer`:

- `claude`: [Claude CLI](https://docs.anthropic.com/en/docs/claude-code)
- `codex`: [Codex CLI](https://developers.openai.com/codex/cli/)
- `cursor`: `cursor-agent`
- `gemini`: `gemini`

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/easterncoder/aicandoit.git
cd aicandoit
```

### 2. Install the launcher

```bash
sudo install -m 0755 bin/aicandoit /usr/local/bin/aicandoit
```

If you prefer to run from the repo directly:

```bash
chmod +x bin/aicandoit
```

### 3. Install the shared skills

This repository ships the workflow skills in `skills/`.

Install them for Claude when you pass `--coder claude`, `--planner claude`, or `--reviewer claude`:

```bash
mkdir -p "$HOME/.claude/skills"
cp -R skills/. "$HOME/.claude/skills/"
```

If you pass `--coder codex`, `--planner codex`, or `--reviewer codex`, also install for Codex:

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

If you pass `--coder cursor`, `--planner cursor`, or `--reviewer cursor`, make sure your `cursor-agent` setup exposes the same workflow commands from this repository:

- `/plan-it`
- `/plan-review`
- `/plan-update`
- `/code-it`
- `/code-review`
- `/code-fix`

If you pass `--coder gemini`, `--planner gemini`, or `--reviewer gemini`, Gemini CLI should run in non-interactive prompt mode and use `--resume latest` for looped review or fix steps.
Gemini uses the same slash skill commands:

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

Verify each CLI you plan to pass to `--coder`, `--planner`, or `--reviewer`:

```bash
claude --version
```

```bash
codex --version
```

```bash
cursor-agent --version
```

```bash
gemini --version
```

Run the deterministic auto-branch helper coverage:

```bash
bash tests/test-aicandoit-auto-branch.sh
```

Run Gemini coverage:

```bash
bash tests/test-aicandoit-gemini.sh
```

## Usage

```bash
aicandoit --coder <cli[/model]> --reviewer <cli[/model]> [--planner <cli[/model]>] [--mode <stage>] [--worktree] [--branch <name> | --current-branch | --auto-branch] <prompt...>
```

Examples:

```bash
aicandoit --coder claude --reviewer codex --branch feature/api-caching "add caching to API responses"
aicandoit -C claude -R cursor -B feature/api-caching "add caching to API responses"
aicandoit --coder claude --reviewer codex --current-branch "fix the login bug"
aicandoit --coder codex --reviewer claude --auto-branch "fix gh issue 24"
aicandoit --coder codex --reviewer claude --auto-branch "work on README.md examples"
aicandoit --coder codex --reviewer claude --auto-branch --worktree "fix gh issue 24"
aicandoit --coder codex --reviewer claude --branch feature/worktree-smoke --worktree "run workflow in branch worktree"
aicandoit --planner codex --coder claude --reviewer cursor --current-branch "add model routing"
aicandoit --coder gemini --reviewer claude --current-branch "add model routing"
aicandoit --planner gemini --coder codex --reviewer cursor --current-branch "add model routing"
aicandoit --coder gemini/gemini-2.5-pro --reviewer gemini/gemini-2.5-flash --current-branch "add model routing"
aicandoit --coder cursor/composer-1 --reviewer claude/claude-opus-4-6 --current-branch "add model routing"
aicandoit --coder claude/claude-sonnet-4-6 --reviewer claude/claude-opus-4-6 --current-branch "add feature"
aicandoit --coder claude --reviewer codex --current-branch --mode plan "add staging support"
aicandoit --coder claude --reviewer codex --current-branch --mode plan-review "add staging support"
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
