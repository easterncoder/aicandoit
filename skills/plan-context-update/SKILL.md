---
name: plan-context-update
description: Refresh context artifacts for the `plan-context-update` command. Use when the user asks to run `plan-context-update` and only `.aicandoit/branches/{branch-slug}/context/issues`, `.aicandoit/branches/{branch-slug}/context/prs`, and `.aicandoit/branches/{branch-slug}/context/repos` need updates. If `.aicandoit/branches/{branch-slug}/plan.md` must be created or changed, use `plan-it`.
---

# Plan Context Update

## Goal

Refresh `.aicandoit/branches/{branch-slug}/context/*` with accurate and current project context.

## Branch Scope

1. Resolve `branch-slug` from the active git branch:
   - Run `git rev-parse --abbrev-ref HEAD`.
   - If the result is `HEAD`, use `detached-$(git rev-parse --short HEAD)`.
   - Replace `/` with `_` in the final value.
2. Use `.aicandoit/branches/{branch-slug}` as the artifact root for this skill.
3. Do not write context updates to top-level `.aicandoit/context/*`.
4. Apply the shared guard in `.aicandoit/references/default-branch-guard.md` before proceeding.

## Workflow

1. Ensure .aicandoit/ and .aicandoit/references/ exist in this order before any .aicandoit/ file lookup.
2. If .aicandoit/references/default-branch-guard.md does not exist, create it using the exact guard content in Failure Handling.
3. Run .aicandoit/references/default-branch-guard.md and stop immediately if it blocks execution.
4. Ensure .aicandoit/branches/{branch-slug} exists before reading or writing branch artifacts.
5. Ensure .aicandoit/branches/{branch-slug}/context/issues, .aicandoit/branches/{branch-slug}/context/prs, and .aicandoit/branches/{branch-slug}/context/repos exist before inspecting existing context files.
6. Inspect existing context files under `.aicandoit/branches/{branch-slug}/context/issues`, `.aicandoit/branches/{branch-slug}/context/prs`, and `.aicandoit/branches/{branch-slug}/context/repos`.
7. Pull latest relevant GitHub data for the current task scope.
8. Update existing context files or add new ones where needed.
9. Keep each file focused, factual, and traceable to source data.
10. Preserve useful existing context that is still valid.
11. Do not modify `.aicandoit/branches/{branch-slug}/plan.md` in this workflow.

## Output Rules

- Keep context grouped by folder purpose (`issues`, `prs`, `repos`).
- Use stable, readable filenames.
- Remove stale or contradictory statements when updating.

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

- If .aicandoit/branches/{branch-slug} does not exist, create it.
- If `.aicandoit/branches/{branch-slug}/context/issues`, `.aicandoit/branches/{branch-slug}/context/prs`, or `.aicandoit/branches/{branch-slug}/context/repos` do not exist, create them.
- If GitHub data is unavailable, update from local data and write status notes in `.aicandoit/branches/{branch-slug}/context/repos/_sync-status.md`.
- In `_sync-status.md`, add `- Pending remote sync: <reason>` entries for unresolved remote data.
- If `.aicandoit/references/default-branch-guard.md` blocks execution, do not write or update any context files.
