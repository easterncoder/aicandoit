---
name: plan-review
description: Review `.aicandoit/branches/{branch-slug}/plan.md` for the `plan-review` command. Use when the user asks to run `plan-review`, then write review results to `.aicandoit/branches/{branch-slug}/plan-review.md`, honoring `CLARIFICATIONS`, and write `ALL GOOD` when no issues remain.
---

# Plan Review

## Goal

Review `.aicandoit/branches/{branch-slug}/plan.md` for correctness, completeness, and execution clarity for a junior developer.

## Branch Scope

1. Resolve `branch-slug` from the active git branch:
   - Run `git rev-parse --abbrev-ref HEAD`.
   - If the result is `HEAD`, use `detached-$(git rev-parse --short HEAD)`.
   - Replace `/` with `_` in the final value.
2. Use `.aicandoit/branches/{branch-slug}` as the artifact root for this skill.
3. Do not write review output to top-level `.aicandoit/plan-review.md`.
4. Apply the shared guard in `.aicandoit/references/default-branch-guard.md` before proceeding.

## Workflow

1. Ensure .aicandoit/ and .aicandoit/references/ exist in this order before any .aicandoit/ file lookup.
2. If .aicandoit/references/default-branch-guard.md does not exist, create it using the exact guard content in Failure Handling.
3. Run .aicandoit/references/default-branch-guard.md and stop immediately if it blocks execution.
4. Ensure .aicandoit/branches/{branch-slug} exists before reading or writing branch artifacts.
5. Ensure .aicandoit/ and .aicandoit/templates/ exist in this order before any .aicandoit/ template lookup.
6. If the required template file does not exist, create it using the exact template content in Failure Handling.
7. Read `.aicandoit/branches/{branch-slug}/plan.md`.
8. Check for a `CLARIFICATIONS` section and treat listed questions as open items.
9. Evaluate ambiguity, missing dependencies, ordering problems, and unverifiable steps.
10. Use `.aicandoit/templates/plan-review.md` as the structural baseline for `.aicandoit/branches/{branch-slug}/plan-review.md` when findings exist.
11. Write results to `.aicandoit/branches/{branch-slug}/plan-review.md` using the output format below.
12. If the plan is fully acceptable, write exactly `ALL GOOD` to `.aicandoit/branches/{branch-slug}/plan-review.md`.
13. If output is `ALL GOOD`, also state that all is good in the user-facing response.

## Output Format

- If there are no findings, write exactly `ALL GOOD`.
- Otherwise, list findings ordered by severity using:
`- severity: <critical|high|medium|low>; file: <path:line|N/A>; impact: <risk>; fix: <concrete action>`

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
- If .aicandoit/templates/plan-review.md does not exist, create it with exactly this content:

```md
# Plan Review

Findings are listed below in descending severity order.

Format per finding:
`- severity: <critical|high|medium|low>; file: <path:line|N/A>; impact: <risk>; fix: <concrete action>`

---
```

- If .aicandoit/branches/{branch-slug} does not exist, create it.
- If `.aicandoit/branches/{branch-slug}/plan.md` is missing, ask the user to run `plan-it` first.
- If `.aicandoit/references/default-branch-guard.md` blocks execution, do not write or update any review files.

## Review Focus

- Missing prerequisites
- Vague implementation steps
- Unclear acceptance criteria
- Risky sequencing
- Gaps between scope and plan steps
