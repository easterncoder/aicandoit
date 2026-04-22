#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=bin/aicandoit
source "${REPO_ROOT}/bin/aicandoit"

# Fail with a readable test message.
fail() {
  echo "error: $1" >&2
  exit 1
}

# Assert that two strings match exactly.
assert_equals() {
  local expected="$1"
  local actual="$2"
  local label="$3"

  if [[ "$expected" != "$actual" ]]; then
    fail "$label expected '$expected' but got '$actual'"
  fi
}

# Assert that a name is accepted by git check-ref-format --branch.
assert_valid_branch_ref() {
  local branch_name="$1"
  local label="$2"

  if ! git check-ref-format --branch "$branch_name" >/dev/null 2>&1; then
    fail "$label produced invalid branch ref '$branch_name'"
  fi
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FIXTURE_REPO="${TMP_DIR}/repo"
git init -q -b main "$FIXTURE_REPO"
git -C "$FIXTURE_REPO" config user.name "Fixture User"
git -C "$FIXTURE_REPO" config user.email "fixture@example.com"

mkdir -p "${FIXTURE_REPO}/docs" "${FIXTURE_REPO}/bin"
printf '# AI Can Do It\n\nPlan it.\n' > "${FIXTURE_REPO}/README.md"
printf 'Guide title\n\nMore text.\n' > "${FIXTURE_REPO}/docs/guide.txt"
printf '\x00\x01\x02' > "${FIXTURE_REPO}/bin/blob.bin"
head -c 70000 /dev/zero | tr '\0' 'a' > "${FIXTURE_REPO}/docs/large.txt"

git -C "$FIXTURE_REPO" add README.md docs/guide.txt bin/blob.bin docs/large.txt
git -C "$FIXTURE_REPO" commit -qm 'chore: initialize fixture'

export AICANDOIT_ISSUE_TITLE_24='Add source aware auto branch mode'

issue_branch="$(cd "$FIXTURE_REPO" && resolve_auto_branch_name 'fix gh issue 24' "$FIXTURE_REPO")"
assert_equals 'auto/issue-24-add-source-aware-auto-branch-mode' "$issue_branch" 'issue branch'
assert_valid_branch_ref "$issue_branch" 'issue branch'

file_branch="$(cd "$FIXTURE_REPO" && resolve_auto_branch_name 'work on `README.md`.' "$FIXTURE_REPO")"
assert_equals 'auto/readme-md-ai-can-do-it' "$file_branch" 'file branch'
assert_valid_branch_ref "$file_branch" 'file branch'

text_file_branch="$(cd "$FIXTURE_REPO" && resolve_auto_branch_name 'update docs/guide.txt next' "$FIXTURE_REPO")"
assert_equals 'auto/guide-txt-guide-title' "$text_file_branch" 'text file branch'
assert_valid_branch_ref "$text_file_branch" 'text file branch'

binary_fallback_branch="$(cd "$FIXTURE_REPO" && resolve_auto_branch_name 'inspect ./bin/blob.bin' "$FIXTURE_REPO")"
assert_equals 'auto/inspect-bin-blob-bin' "$binary_fallback_branch" 'binary fallback branch'
assert_valid_branch_ref "$binary_fallback_branch" 'binary fallback branch'

large_file_fallback_branch="$(cd "$FIXTURE_REPO" && resolve_auto_branch_name 'check docs/large.txt' "$FIXTURE_REPO")"
assert_equals 'auto/check-docs-large-txt' "$large_file_fallback_branch" 'large file fallback branch'
assert_valid_branch_ref "$large_file_fallback_branch" 'large file fallback branch'

priority_issue_branch="$(cd "$FIXTURE_REPO" && resolve_auto_branch_name 'fix gh issue 24 in README.md' "$FIXTURE_REPO")"
assert_equals 'auto/issue-24-add-source-aware-auto-branch-mode' "$priority_issue_branch" 'priority issue over file'
assert_valid_branch_ref "$priority_issue_branch" 'priority issue over file'

priority_file_branch="$(cd "$FIXTURE_REPO" && resolve_auto_branch_name 'update docs/guide.txt now' "$FIXTURE_REPO")"
assert_equals 'auto/guide-txt-guide-title' "$priority_file_branch" 'priority file over prompt fallback'
assert_valid_branch_ref "$priority_file_branch" 'priority file over prompt fallback'

priority_prompt_branch="$(cd "$FIXTURE_REPO" && resolve_auto_branch_name 'fix issue: login / signup!!!' "$FIXTURE_REPO")"
assert_equals 'auto/fix-issue-login-signup' "$priority_prompt_branch" 'priority prompt fallback'
assert_valid_branch_ref "$priority_prompt_branch" 'priority prompt fallback'

git -C "$FIXTURE_REPO" branch 'auto/issue-24-add-source-aware-auto-branch-mode'
collision_branch="$(cd "$FIXTURE_REPO" && resolve_auto_branch_name 'fix gh issue 24' "$FIXTURE_REPO")"
assert_equals 'auto/issue-24-add-source-aware-auto-branch-mode-2' "$collision_branch" 'collision branch'
assert_valid_branch_ref "$collision_branch" 'collision branch'

STUB_DIR="${TMP_DIR}/stubs"
mkdir -p "$STUB_DIR"

printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "${STUB_DIR}/gh"
printf '%s\n' '#!/usr/bin/env bash' 'branch="$(git branch --show-current)"' 'slug="${branch//\//_}"' 'mkdir -p ".aicandoit/branches/${slug}"' 'printf "Template target: `.aicandoit/branches/{branch-slug}/plan.md`\n" > ".aicandoit/branches/${slug}/plan.md"' 'exit 0' > "${STUB_DIR}/codex"
printf '%s\n' '#!/usr/bin/env bash' 'branch="$(git branch --show-current)"' 'slug="${branch//\//_}"' 'mkdir -p ".aicandoit/branches/${slug}"' 'printf "ALL GOOD\n" > ".aicandoit/branches/${slug}/plan-review.md"' 'printf "ALL GOOD\n" > ".aicandoit/branches/${slug}/code-review.md"' 'exit 0' > "${STUB_DIR}/claude"
chmod +x "${STUB_DIR}/gh" "${STUB_DIR}/codex" "${STUB_DIR}/claude"

(
  cd "$FIXTURE_REPO"
  PATH="${STUB_DIR}:$PATH" "$REPO_ROOT/bin/aicandoit" --coder codex --reviewer claude --auto-branch 'work on `README.md`.' --mode plan
)

end_to_end_branch="$(git -C "$FIXTURE_REPO" branch --show-current)"
assert_equals 'auto/readme-md-ai-can-do-it' "$end_to_end_branch" 'end to end branch'
assert_valid_branch_ref "$end_to_end_branch" 'end to end branch'
[[ -f "${FIXTURE_REPO}/.aicandoit/branches/auto_readme-md-ai-can-do-it/plan.md" ]] || fail 'end to end plan missing'
[[ -f "${FIXTURE_REPO}/.aicandoit/branches/auto_readme-md-ai-can-do-it/plan-review.md" ]] || fail 'end to end plan review missing'

echo 'auto-branch helper tests passed'
