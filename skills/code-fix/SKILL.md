---
name: code-fix
description: Apply review fixes for the `code-fix` command. Use when the user asks to run `code-fix`, read `.aicandoit/branches/{branch-slug}/code-review.md` and `.aicandoit/branches/{branch-slug}/plan.md`, implement corrections, create a new commit, and save a summary in `.aicandoit/branches/{branch-slug}/code-fix.md`.
---

# Code Fix

## Goal

Implement corrections from `.aicandoit/branches/{branch-slug}/code-review.md` and document completed fixes in `.aicandoit/branches/{branch-slug}/code-fix.md`.

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
8. Plan and implement fixes for each applicable review finding ID.
9. Use `.aicandoit/templates/code-fix.md` as the structural baseline for `.aicandoit/branches/{branch-slug}/code-fix.md`.
10. Map every finding ID exactly once in `.aicandoit/branches/{branch-slug}/code-fix.md` using the output format below.
11. Run relevant validation for modified areas.
12. Save `.aicandoit/branches/{branch-slug}/code-fix.md`.
13. Ensure that tests and coding standards pass.
14. Create a new Conventional Commit for the fix set.

## Commit Rules

- Create a new commit, do not amend.
- Keep commit scope aligned with reviewed findings.
- Sign the commit.

## Output Format

- For each review finding ID, write exactly one mapping entry:
`- id: F001; status: <fixed|deferred|not-applicable>; summary: <what changed or why deferred>; evidence: <files and/or validation commands>`

## Finding ID Contract

- Every `F###` in `.aicandoit/branches/{branch-slug}/code-review.md` must appear exactly once in `.aicandoit/branches/{branch-slug}/code-fix.md`.
- Do not add IDs that are not present in `.aicandoit/branches/{branch-slug}/code-review.md`.
- Preserve ID order from `.aicandoit/branches/{branch-slug}/code-review.md`.

## Quality Bar

- Address root causes, not only symptoms.
- Keep fixes scoped to reviewed findings unless a required dependency appears.
- Ensure `.aicandoit/branches/{branch-slug}/code-fix.md` maps fixes to findings.

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
