---
name: code-it
description: Execute `.aicandoit/branches/{branch-slug}/plan.md` for the `code-it` command. Use when the user asks to run `code-it`, implement the planned code changes, validate them, and create a new commit.
---

# Code It

## Goal

Implement the approved plan in `.aicandoit/branches/{branch-slug}/plan.md` and commit the work as a new commit.

## Branch Scope

1. Resolve `branch-slug` from the active git branch:
   - Run `git rev-parse --abbrev-ref HEAD`.
   - If the result is `HEAD`, use `detached-$(git rev-parse --short HEAD)`.
   - Replace `/` with `_` in the final value.
2. Read planning artifacts from `.aicandoit/branches/{branch-slug}`.
3. Do not read top-level `.aicandoit/plan.md`.

## Workflow

1. Ensure .aicandoit/branches/{branch-slug} exists before reading .aicandoit/branches/{branch-slug}/plan.md.
2. Read `.aicandoit/branches/{branch-slug}/plan.md` fully before editing.
3. Implement plan steps in order, updating code, tests, and docs as required.
4. Run relevant checks and tests for changed areas.
5. Summarize what changed and what validation passed.
6. Ensure that tests and coding standards pass.
7. Create a new commit with a Conventional Commit message.

## Commit Rules

- Create a new commit, do not amend.
- Keep commit scope aligned with the plan.
- Use factual, concise commit text.
- Include a closes line if the commit closes a github issue.
- Sign the commit.

## Failure Handling

- If .aicandoit/branches/{branch-slug} does not exist, create it.
- If `.aicandoit/branches/{branch-slug}/plan.md` is missing, ask the user to run `plan-it` first.
