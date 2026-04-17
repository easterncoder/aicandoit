---
name: code-fix-amend
description: Apply review fixes for the `code-fix-amend` command. Use when the user asks to run `code-fix-amend`, follow the `code-fix` workflow, but amend the previous commit instead of creating a new one.
---

# Code Fix Amend

## Goal

Apply `.aicandoit/branches/{branch-slug}/code-review.md` corrections and amend the latest commit with the fix changes.

## Branch Scope

1. Resolve `branch-slug` from the active git branch:
   - Run `git rev-parse --abbrev-ref HEAD`.
   - If the result is `HEAD`, use `detached-$(git rev-parse --short HEAD)`.
   - Replace `/` with `_` in the final value.
2. Use `.aicandoit/branches/{branch-slug}` as the artifact root for this skill.
3. Do not write fix output to top-level `.aicandoit/code-fix.md`.

## Workflow

1. Ensure .aicandoit/ and .aicandoit/templates/ exist in this order before any .aicandoit/ template lookup.
2. If the required template file does not exist, create it using the exact template content in Failure Handling.
3. Ensure .aicandoit/branches/{branch-slug} exists before reading or writing branch artifacts.
4. Read `.aicandoit/branches/{branch-slug}/code-review.md`.
5. If `.aicandoit/branches/{branch-slug}/code-review.md` is exactly `ALL GOOD`, respond that all is good and stop.
6. Read `.aicandoit/branches/{branch-slug}/plan.md` for intended scope.
7. Extract all finding IDs from `.aicandoit/branches/{branch-slug}/code-review.md` (`F001`, `F002`, ...).
8. Implement fixes for review findings by ID.
9. Use `.aicandoit/templates/code-fix.md` as the structural baseline for `.aicandoit/branches/{branch-slug}/code-fix.md`.
10. Map every finding ID exactly once in `.aicandoit/branches/{branch-slug}/code-fix.md` using the output format below.
11. Run relevant validation for modified areas.
12. Save `.aicandoit/branches/{branch-slug}/code-fix.md`.
13. Amend the previous commit instead of creating a new commit.

## Commit Rules

- Amend only the latest commit in scope.
- Keep amended commit message accurate and concise.
- Sign the amended commit.

## Output Format

- For each review finding ID, write exactly one mapping entry:
`- id: F001; status: <fixed|deferred|not-applicable>; summary: <what changed or why deferred>; evidence: <files and/or validation commands>`

## Finding ID Contract

- Every `F###` in `.aicandoit/branches/{branch-slug}/code-review.md` must appear exactly once in `.aicandoit/branches/{branch-slug}/code-fix.md`.
- Do not add IDs that are not present in `.aicandoit/branches/{branch-slug}/code-review.md`.
- Preserve ID order from `.aicandoit/branches/{branch-slug}/code-review.md`.

## Quality Bar

- Keep amended commit message accurate and concise.
- Confirm all addressed findings are reflected in `.aicandoit/branches/{branch-slug}/code-fix.md`.
- Avoid unrelated changes in the amend operation.

## Failure Handling

- If `.aicandoit/branches/{branch-slug}/code-review.md` has findings without `F###` IDs, stop and normalize review output first.
- If `.aicandoit/` does not exist, create it.
- If `.aicandoit/templates/` does not exist, create it.
- If .aicandoit/templates/code-fix.md does not exist, create it with exactly this content:

```md
# CODE FIX

- id: F001; status: <fixed|deferred|not-applicable>; summary: <what changed or why deferred>; evidence: <files and/or validation commands>
```

- If .aicandoit/branches/{branch-slug} does not exist, create it.
- If `.aicandoit/branches/{branch-slug}/code-review.md` is missing, ask the user to run `code-review` first.
