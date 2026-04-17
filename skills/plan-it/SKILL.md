---
name: plan-it
description: Create or update a detailed execution plan for the `plan-it` command. Use when the user asks to run `plan-it`, draft a plan, or revise `.aicandoit/branches/{branch-slug}/plan.md` scope. If the request is only to refresh `.aicandoit/branches/{branch-slug}/context/*` without changing `.aicandoit/branches/{branch-slug}/plan.md`, use `plan-context-update`.
---

# Plan It

## Goal

Write a clear, junior-ready plan to `.aicandoit/branches/{branch-slug}/plan.md` and persist supporting context under `.aicandoit/branches/{branch-slug}/context/*`.

## Branch Scope

1. Resolve `branch-slug` from the active git branch:
   - Run `git rev-parse --abbrev-ref HEAD`.
   - If the result is `HEAD`, use `detached-$(git rev-parse --short HEAD)`.
   - Replace `/` with `_` in the final value.
2. Use `.aicandoit/branches/{branch-slug}` as the artifact root for this skill.
3. Do not write planning artifacts to top-level `.aicandoit/*.md`.
4. Apply the shared guard in `.aicandoit/references/default-branch-guard.md` before proceeding.

## Required Outputs

- `.aicandoit/branches/{branch-slug}/plan.md`
- `.aicandoit/branches/{branch-slug}/context/issues/*`
- `.aicandoit/branches/{branch-slug}/context/prs/*`
- `.aicandoit/branches/{branch-slug}/context/repos/*`

## Workflow

1. Ensure the shared parent directories exist in this order before any `.aicandoit/` file lookup:
   - `.aicandoit/`
   - `.aicandoit/references/`
2. If `.aicandoit/references/default-branch-guard.md` does not exist, create it using the exact guard content in `Failure Handling`.
3. Run `.aicandoit/references/default-branch-guard.md` and stop immediately if it blocks execution.
4. If scope is missing or the user runs `plan-it` without details, ask `What should I plan for?` and wait for the answer.
5. Confirm this is a planning task, not a context-only refresh task.
6. Read current task scope from the conversation and repository state.
7. Gather issue, PR, and repository context from GitHub when relevant.
8. Ensure the remaining planning directories exist in this order before writing context or plan files:
   - `.aicandoit/templates/`
   - `.aicandoit/branches/{branch-slug}/`
   - `.aicandoit/branches/{branch-slug}/context/issues`
   - `.aicandoit/branches/{branch-slug}/context/prs`
   - `.aicandoit/branches/{branch-slug}/context/repos`
9. Save detailed context artifacts into:
   - `.aicandoit/branches/{branch-slug}/context/issues`
   - `.aicandoit/branches/{branch-slug}/context/prs`
   - `.aicandoit/branches/{branch-slug}/context/repos`
10. If `.aicandoit/templates/plan.md` does not exist, create it using the exact template content in `Failure Handling`.
11. Use `.aicandoit/templates/plan.md` as the structural baseline for `.aicandoit/branches/{branch-slug}/plan.md`.
12. Fill `CONTEXT > ISSUES`, `PRS`, `REPOS`, and `NOTES` with bullet list items. If empty, write `- None`.
13. Fill implementation sections with explicit file paths, commands, validation steps, and acceptance criteria.
14. Verify the final instructions are unambiguous before finishing:
   - No `Steps` or `Validation` entry in the generated plan references a file under `.aicandoit/` unless an earlier `Steps` entry explains how to create that file's parent directory.
   - No `Steps` or `Validation` entry in the generated plan tells the implementor to use `.aicandoit/references/default-branch-guard.md` before an earlier `Steps` entry or `Failure Handling` rule explains how to create it.
   - No `Steps` or `Validation` entry in the generated plan tells the implementor to use `.aicandoit/templates/plan.md` before an earlier `Steps` entry or `Failure Handling` rule explains how to create it.
   - The finished plan is explicit enough for a junior developer to execute without guessing.

## Failure Handling

- If `.aicandoit/` does not exist, create it.
- If `.aicandoit/references/` does not exist, create it.
- If `.aicandoit/references/default-branch-guard.md` does not exist, create it with exactly this content:

```md
# Default Branch Guard

Use this shared guard in all planning workflows before reading or writing branch-scoped artifacts.

## Procedure

1. Resolve `current-branch`:
   - Run `git rev-parse --abbrev-ref HEAD`.
2. Resolve `default-branch`:
   - Run `git symbolic-ref --quiet --short refs/remotes/origin/HEAD | sed 's@^origin/@@'`.
   - If empty and `main` exists (remote or local), use `main`.
   - Else if `master` exists (remote or local), use `master`.
   - Else if `develop` exists (remote or local), use `develop`.
   - Else use `main`.
3. Compare:
   - If `current-branch` equals the resolved default branch name, stop.

## Required User Message

- `Planning commands are blocked on the default branch. Check out a feature branch and retry.`

## Important

- Do not compare against the literal text `default-branch`.
- If this guard blocks execution, do not write or update planning artifacts.
```

- If `.aicandoit/templates/` does not exist, create it.
- If `.aicandoit/templates/plan.md` does not exist, create it with exactly this content:

```md
Template target: `.aicandoit/branches/{branch-slug}/plan.md`

# CONTEXT

## ISSUES

- None

## PRS

- None

## REPOS

- None

## NOTES

- None

# IMPLEMENTATION PLAN

## Scope

- [Describe the implementation scope.]

## Assumptions

- None

## Steps

1. [Step with explicit file paths and commands.]

## Validation

- [Command]: [Expected result]

## Acceptance Criteria

- [Measurable completion criterion.]

## Risks

- None
```

- If `.aicandoit/branches/{branch-slug}` does not exist, create it.
- If `.aicandoit/branches/{branch-slug}/context/issues`, `.aicandoit/branches/{branch-slug}/context/prs`, or `.aicandoit/branches/{branch-slug}/context/repos` do not exist, create them.
- If `.aicandoit/branches/{branch-slug}/plan.md` is missing, create it from `.aicandoit/templates/plan.md`, which must exist first.
- If GitHub data is unavailable, continue with local context and add `- Pending remote sync: <reason>` under `CONTEXT > NOTES`.
- If `.aicandoit/references/default-branch-guard.md` blocks execution, do not write or update any planning files.

## Quality Bar

- Keep statements factual and specific.
- Prefer concrete steps over abstract guidance.
- Keep tasks ordered and verifiable.
