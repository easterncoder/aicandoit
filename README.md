# AI Can Do It

AI Can Do It is a unified Bash launcher that runs a plan-and-implement loop using any supported coder and reviewer CLI pair.

- `bin/aicandoit` accepts `--coder`, `--reviewer`, optional `--planner`, optional `--mode`, optional `--worktree`, and branch selection via `--branch`, `--current-branch`, or `--auto-branch`.
- Accepted CLIs are `claude`, `codex`, `cursor`, and `gemini`, optionally with a model suffix in `cli/model` form.

- Author: Mike Lopez <e@mikelopez.com>
- Copyright (C) 2026 Mike Lopez <e@mikelopez.com>

## What It Does

`aicandoit` follows this control flow:

1. Accept `--branch <name>`, `--current-branch`, or `--auto-branch` plus a prompt. When all three are omitted, infer current-branch mode when `.aicandoit/branches/<current-branch-slug>` already exists.
2. When `--auto-branch` is passed, inspect the prompt in conservative order: GitHub issue references such as `gh issue 24`, then readable repo-local text files such as `README.md`, then the raw prompt text.
3. Resolve a deterministic branch name before checkout or worktree setup. Existing local branch names receive a numeric suffix such as `-2`.
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
| `--auto-branch` | | No | Derive a new branch name from issue references, file references, or prompt text |

The `cli/model` format passes `--model <model>` to the chosen CLI. When no model is specified the CLI uses its own default. For `cursor`, the built-in default is `gpt-5.3-codex-high`.
The `--mode` flag runs only the selected stage. `plan-review` requires an existing branch plan and creates `plan-review.md` on its first review pass when needed. `code-review` requires that you have already run the matching `code` stage on the same branch.
The `--verbose` flag shows CLI tool output and merges stderr into stdout so all tool output appears on stdout.
If `--branch`, `--current-branch`, and `--auto-branch` are all omitted, the launcher checks for `.aicandoit/branches/<current-branch-slug>`; if it does not exist, it fails with `error: pass --branch <name>, --current-branch, or --auto-branch`.
`--auto-branch` is mutually exclusive with `--branch` and `--current-branch`.
With `--worktree`, the launcher uses `<repo-root>/.aicandoit/branches/<branch-slug>/worktree`. `--worktree` does not support `--current-branch`.

## Auto Branch Rules

`--auto-branch` resolves branch names in this order:

1. GitHub issue references such as `gh issue 24` or `issue 24`. When the issue title is available, the generated branch looks like `auto/issue-24-short-title`. If GitHub access fails, the fallback stays deterministic and still uses `auto/issue-24`.
2. Repo-local file references such as `README.md` or `./docs/guide.txt`. Only readable text files under the current repository root are considered. Directories, binary files, and files above `AUTO_BRANCH_FILE_MAX_BYTES` are ignored.
3. Raw prompt text. This is the fallback when no issue or valid file source resolves.

For file-based resolution, the launcher reads only the first `AUTO_BRANCH_FILE_SNIPPET_BYTES` bytes and uses the first non-empty line together with the basename to keep the slug stable and bounded.
All auto-derived branch names pass through a single ref-safety gate and are validated with `git check-ref-format --branch` before any checkout or creation step.
If normalization still cannot produce a valid branch ref, the launcher fails with a clear error instead of running `git checkout -b` with an unsafe name.
Example: `--auto-branch "fix issue: login / signup"` resolves to a safe branch such as `auto/fix-issue-login-signup`.

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
