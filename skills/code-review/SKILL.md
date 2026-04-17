---
name: code-review
description: Perform branch review for the `code-review` command. Use when the user asks to run `code-review`, evaluate changes against `.aicandoit/branches/{branch-slug}/plan.md`, use `.aicandoit/branches/{branch-slug}/code-fix.md` when present, and write results to `.aicandoit/branches/{branch-slug}/code-review.md` with `ALL GOOD` when no findings exist.
allowed-tools:
  - exec_command
  - apply_patch
---

# Code Review

## Goal

Review branch changes against plan intent and code quality expectations, then save the review to `.aicandoit/branches/{branch-slug}/code-review.md`.

## Branch Scope

1. Resolve `branch-slug` from the active git branch:
   - Run `git rev-parse --abbrev-ref HEAD`.
   - If the result is `HEAD`, use `detached-$(git rev-parse --short HEAD)`.
   - Replace `/` with `_` in the final value.
2. Use `.aicandoit/branches/{branch-slug}` as the artifact root for this skill.
3. Do not write review output to top-level `.aicandoit/code-review.md`.

## Workflow

1. Ensure .aicandoit/ and .aicandoit/templates/ exist in this order before any .aicandoit/ template lookup.
2. If the required template file does not exist, create it using the exact template content in Failure Handling.
3. Ensure .aicandoit/branches/{branch-slug} exists before reading or writing branch artifacts.
4. Read `.aicandoit/branches/{branch-slug}/plan.md`.
5. If present, read existing `.aicandoit/branches/{branch-slug}/code-review.md` for prior context.
6. If present, read `.aicandoit/branches/{branch-slug}/code-fix.md` for implemented fixes.
7. Review current branch changes for regressions, risks, and missing coverage.
8. Use `.aicandoit/templates/code-review.md` as the structural baseline for `.aicandoit/branches/{branch-slug}/code-review.md` when findings exist.
9. Save review results to `.aicandoit/branches/{branch-slug}/code-review.md` using the output format below.
10. If there are no findings, write exactly `ALL GOOD`.
11. If output is `ALL GOOD`, also say all is good in the user-facing response.

## Output Format

- If there are no findings, write exactly `ALL GOOD`.
- Otherwise, list findings ordered by severity using:
`- id: F001; severity: <critical|high|medium|low>; file: <path:line|N/A>; impact: <risk>; fix: <concrete action>`

## Finding ID Contract

- Use sequential IDs in this exact format: `F001`, `F002`, `F003`, ...
- Assign one unique ID per finding and do not reuse IDs for different findings.
- Keep IDs stable within the current review output.

## Severity Definitions

- `critical`: Data loss, security exposure, or release blocker.
- `high`: Functional break or high-risk regression likely in common paths.
- `medium`: Correctness or maintainability issue with moderate user impact.
- `low`: Minor gap, style issue, or low-risk improvement.

## Review Priorities

- Functional correctness
- Regression risk
- Missing edge-case handling
- Test coverage gaps
- Plan alignment

## Trigger Examples

- `code-review this branch against .aicandoit/branches/{branch-slug}/plan.md`
- `run code-review and update .aicandoit/branches/{branch-slug}/code-review.md`
- `review current changes and mark ALL GOOD if clean`

## Failure Handling

- If `.aicandoit/` does not exist, create it.
- If `.aicandoit/templates/` does not exist, create it.
- If .aicandoit/templates/code-review.md does not exist, create it with exactly this content:

```md
# Code Review

Findings are listed below in descending severity order.

Format per finding:
`- id: F001; severity: <critical|high|medium|low>; file: <path:line|N/A>; impact: <risk>; fix: <concrete action>`

---
```

- If .aicandoit/branches/{branch-slug} does not exist, create it.
- If `.aicandoit/branches/{branch-slug}/plan.md` is missing, ask the user to run `plan-it` first.
- If findings exist but IDs cannot be assigned cleanly, stop and fix the output format before saving.
