---
name: plan-update
description: Update `.aicandoit/branches/{branch-slug}/plan.md` for the `plan-update` command. Use when the user asks to run `plan-update` by applying feedback from `.aicandoit/branches/{branch-slug}/plan-review.md`, handling `ALL GOOD`, and adding `CLARIFICATIONS` when needed.
---

# Plan Update

## Goal

Apply review feedback from `.aicandoit/branches/{branch-slug}/plan-review.md` to `.aicandoit/branches/{branch-slug}/plan.md` with zero ambiguity.

## Branch Scope

1. Resolve `branch-slug` from the active git branch:
   - Run `git rev-parse --abbrev-ref HEAD`.
   - If the result is `HEAD`, use `detached-$(git rev-parse --short HEAD)`.
   - Replace `/` with `_` in the final value.
2. Use `.aicandoit/branches/{branch-slug}` as the artifact root for this skill.
3. Do not update top-level `.aicandoit/plan.md` in this workflow.
4. Apply the shared guard in `.aicandoit/references/default-branch-guard.md` before proceeding.

## Workflow

1. Ensure .aicandoit/ and .aicandoit/references/ exist in this order before any .aicandoit/ file lookup.
2. If .aicandoit/references/default-branch-guard.md does not exist, create it using the exact guard content in Failure Handling.
3. Run .aicandoit/references/default-branch-guard.md and stop immediately if it blocks execution.
4. Ensure .aicandoit/branches/{branch-slug} exists before reading or writing branch artifacts.
5. Ensure .aicandoit/ and .aicandoit/templates/ exist in this order before any .aicandoit/ template lookup.
6. If the required template file does not exist, create it using the exact template content in Failure Handling.
7. Read `.aicandoit/branches/{branch-slug}/plan-review.md`.
8. If `.aicandoit/branches/{branch-slug}/plan-review.md` is exactly `ALL GOOD`, respond that all is good and stop.
9. Read the current `.aicandoit/branches/{branch-slug}/plan.md`.
10. Preserve the section structure from `.aicandoit/templates/plan.md` while updating `.aicandoit/branches/{branch-slug}/plan.md`.
11. If unresolved questions remain, add a `CLARIFICATIONS` section with precise questions.
12. Ensure the plan remains junior-ready with concrete steps, file targets, and validation criteria.

## Quality Bar

- Preserve valid existing plan content.
- Resolve every review finding or mark it in `CLARIFICATIONS`.
- Keep the result actionable and testable.

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
- If .aicandoit/templates/plan.md does not exist, create it with exactly this content:

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

- If .aicandoit/branches/{branch-slug} does not exist, create it.
- If `.aicandoit/branches/{branch-slug}/plan-review.md` is missing, ask the user to run `plan-review` first.
- If `.aicandoit/branches/{branch-slug}/plan.md` is missing, ask the user to run `plan-it` first.
- If `.aicandoit/references/default-branch-guard.md` blocks execution, do not write or update any planning files.
