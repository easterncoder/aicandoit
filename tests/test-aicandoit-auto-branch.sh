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

# Assert that the value contains the expected substring.
assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"

  if [[ "$haystack" != *"$needle"* ]]; then
    fail "$label expected to contain '$needle'"
  fi
}

# Assert that the value does not contain the substring.
assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"

  if [[ "$haystack" == *"$needle"* ]]; then
    fail "$label expected not to contain '$needle'"
  fi
}

# Assert that an integer line position is lower than another.
assert_less_than() {
  local left="$1"
  local right="$2"
  local label="$3"

  if (( left >= right )); then
    fail "$label expected $left < $right"
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
printf 'Guide with space\n' > "${FIXTURE_REPO}/docs/My Guide.txt"
printf '\x00\x01\x02' > "${FIXTURE_REPO}/bin/blob.bin"
awk 'BEGIN { for (i=1; i<=140; i++) { printf "LINE%03d_%0150d\n", i, i } }' > "${FIXTURE_REPO}/docs/long-lines.txt"

git -C "$FIXTURE_REPO" add README.md docs/guide.txt docs/My\ Guide.txt bin/blob.bin docs/long-lines.txt
git -C "$FIXTURE_REPO" commit -qm 'chore: initialize fixture'

STUB_DIR="${TMP_DIR}/stubs"
mkdir -p "$STUB_DIR"

printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' "source \"${REPO_ROOT}/bin/aicandoit\"" 'printf "%s\n" "$*" >> "${AICANDOIT_STUB_CODER_ARGS_LOG:-/dev/null}"' 'printf "%s\n" "$*" > "${AICANDOIT_STUB_CODER_ARGS_LAST:-/dev/null}"' '{ printf "===PROMPT===\n"; printf "%s\n" "${*: -1}"; } >> "${AICANDOIT_STUB_CODER_PROMPT_FILE:-/dev/null}"' 'if [[ "$*" == *"\$plan-it "* ]]; then' '  branch="$(git branch --show-current)"' '  slug="$(branch_to_slug "$branch")"' '  mkdir -p ".aicandoit/branches/${slug}"' '  printf "Template target: `.aicandoit/branches/{branch-slug}/plan.md`\n" > ".aicandoit/branches/${slug}/plan.md"' 'fi' 'printf "%s\n" "${AICANDOIT_STUB_CODER_OUTPUT-feat/default}"' > "${STUB_DIR}/codex"
printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' "source \"${REPO_ROOT}/bin/aicandoit\"" 'if [[ "$*" == *"/plan-review"* ]]; then' '  branch="$(git branch --show-current)"' '  slug="$(branch_to_slug "$branch")"' '  mkdir -p ".aicandoit/branches/${slug}"' '  printf "ALL GOOD\n" > ".aicandoit/branches/${slug}/plan-review.md"' '  printf "ALL GOOD\n" > ".aicandoit/branches/${slug}/code-review.md"' 'fi' 'printf "%s\n" "${AICANDOIT_STUB_CODER_OUTPUT-feat/default}"' > "${STUB_DIR}/claude"
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "${AICANDOIT_STUB_CODER_OUTPUT-feat/default}"' > "${STUB_DIR}/cursor-agent"
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "${AICANDOIT_STUB_CODER_OUTPUT-feat/default}"' > "${STUB_DIR}/gemini"
printf '%s\n' '#!/usr/bin/env bash' 'if [[ "$1" == "issue" && "$2" == "view" ]]; then exit 1; fi' 'if [[ "$1" == "pr" && "$2" == "view" ]]; then exit 1; fi' 'exit 0' > "${STUB_DIR}/gh"
chmod +x "${STUB_DIR}/codex" "${STUB_DIR}/claude" "${STUB_DIR}/cursor-agent" "${STUB_DIR}/gemini" "${STUB_DIR}/gh"

export PATH="${STUB_DIR}:$PATH"
export AICANDOIT_STUB_CODER_PROMPT_FILE="${TMP_DIR}/coder-prompt.txt"
export AICANDOIT_STUB_CODER_ARGS_LAST="${TMP_DIR}/coder-args-last.txt"
export AICANDOIT_STUB_CODER_ARGS_LOG="${TMP_DIR}/coder-args.log"
: > "${AICANDOIT_STUB_CODER_PROMPT_FILE}"

CODER_CLI="codex"
CODER_MODEL=""
PLANNER_MODEL=""
REVIEWER_MODEL=""
initialize_runtime_state

export AICANDOIT_ISSUE_TITLE_24='Support AI-generated Conventional Commit branch names'
export AICANDOIT_PR_TITLE_7='Add branch context assembly for auto-branch'
export AICANDOIT_STUB_CODER_OUTPUT='fix/issue-24-ai-branch-name'

issue_refs="$(extract_issue_numbers_from_prompt 'fix gh issue 24 then issue 42')"
assert_equals $'24\n42' "$issue_refs" 'issue reference parsing'

pr_refs="$(extract_pr_numbers_from_prompt 'review gh pr 7 and pull request 11 then pr 13')"
assert_equals $'7\n11\n13' "$pr_refs" 'pr reference parsing'

context_prompt='resolve issue 24 then gh pr 7 and update docs/guide.txt plus README.md and README.md'
context="$(cd "$FIXTURE_REPO" && build_auto_branch_context "$context_prompt" "$FIXTURE_REPO")"
assert_contains "$context" $'RAW PROMPT:\nresolve issue 24 then gh pr 7 and update docs/guide.txt plus README.md and README.md' 'raw prompt context'
assert_contains "$context" $'ISSUES:\n#24: Support AI-generated Conventional Commit branch names' 'issue context'
assert_contains "$context" $'PRS:\n#7: Add branch context assembly for auto-branch' 'pr context'
assert_contains "$context" '[docs/guide.txt]' 'guide path context'
assert_contains "$context" '[README.md]' 'readme path context'

space_path_context="$(cd "$FIXTURE_REPO" && build_auto_branch_context 'inspect "docs/My Guide.txt" now' "$FIXTURE_REPO")"
assert_contains "$space_path_context" '[docs/My Guide.txt]' 'quoted path with spaces context'
assert_contains "$space_path_context" 'Guide with space' 'quoted path snippet context'

readme_open_count="$(printf '%s' "$context" | grep -c '^\[README.md\]$')"
assert_equals '1' "$readme_open_count" 'deduped file path'

prompt_line="$(printf '%s\n' "$context" | grep -n '^RAW PROMPT:' | cut -d: -f1)"
issues_line="$(printf '%s\n' "$context" | grep -n '^ISSUES:' | cut -d: -f1)"
prs_line="$(printf '%s\n' "$context" | grep -n '^PRS:' | cut -d: -f1)"
files_line="$(printf '%s\n' "$context" | grep -n '^FILES:' | cut -d: -f1)"
assert_less_than "$prompt_line" "$issues_line" 'context ordering prompt before issues'
assert_less_than "$issues_line" "$prs_line" 'context ordering issues before prs'
assert_less_than "$prs_line" "$files_line" 'context ordering prs before files'

long_context="$(cd "$FIXTURE_REPO" && build_auto_branch_context 'inspect docs/long-lines.txt' "$FIXTURE_REPO")"
assert_contains "$long_context" 'LINE001_' 'snippet first line present'
assert_not_contains "$long_context" 'LINE120_' 'snippet line cap respected'
assert_not_contains "$long_context" 'LINE121_' 'snippet line cap boundary respected'

validated='feat/support-ai-generated-conventional-branches'
validate_ai_auto_branch_name "$validated"

set +e
validate_ai_auto_branch_name '' >/tmp/aicandoit-auto-branch.err 2>&1
status_empty=$?
set -e
[[ $status_empty -ne 0 ]] || fail 'empty output validation should fail'

set +e
validate_ai_auto_branch_name $'feat/good\nfix/bad' >/tmp/aicandoit-auto-branch.err 2>&1
status_multiline=$?
set -e
[[ $status_multiline -ne 0 ]] || fail 'multiline output validation should fail'

set +e
validate_ai_auto_branch_name 'Fix/not-lowercase-type' >/tmp/aicandoit-auto-branch.err 2>&1
status_upper=$?
set -e
[[ $status_upper -ne 0 ]] || fail 'uppercase type validation should fail'

set +e
validate_ai_auto_branch_name 'fix/not_valid_slug' >/tmp/aicandoit-auto-branch.err 2>&1
status_slug=$?
set -e
[[ $status_slug -ne 0 ]] || fail 'invalid slug validation should fail'

generated_branch="$(cd "$FIXTURE_REPO" && resolve_auto_branch_name 'implement branch naming for issue 24' "$FIXTURE_REPO")"
assert_equals 'fix/issue-24-ai-branch-name' "$generated_branch" 'valid generated branch'

git -C "$FIXTURE_REPO" branch 'fix/issue-24-ai-branch-name'
collision_branch="$(cd "$FIXTURE_REPO" && resolve_auto_branch_name 'implement branch naming for issue 24' "$FIXTURE_REPO")"
assert_equals 'fix/issue-24-ai-branch-name-2' "$collision_branch" 'collision suffix branch'

set +e
(
  export AICANDOIT_STUB_CODER_OUTPUT=''
  cd "$FIXTURE_REPO"
  resolve_auto_branch_name 'implement branch naming for issue 24' "$FIXTURE_REPO"
) >/tmp/aicandoit-auto-branch.err 2>&1
status_empty_output=$?
set -e
[[ $status_empty_output -ne 0 ]] || fail 'empty coder output should fail resolve_auto_branch_name'

set +e
(
  export AICANDOIT_STUB_CODER_OUTPUT=$'feat/ok\nfix/nope'
  cd "$FIXTURE_REPO"
  resolve_auto_branch_name 'implement branch naming for issue 24' "$FIXTURE_REPO"
) >/tmp/aicandoit-auto-branch.err 2>&1
status_multi_output=$?
set -e
[[ $status_multi_output -ne 0 ]] || fail 'multiline coder output should fail resolve_auto_branch_name'

PATH_WITHOUT_GH="${TMP_DIR}/no-gh-path"
mkdir -p "$PATH_WITHOUT_GH"
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "${AICANDOIT_STUB_CODER_OUTPUT-feat/default}"' > "${PATH_WITHOUT_GH}/codex"
chmod +x "${PATH_WITHOUT_GH}/codex"

set +e
(
  unset AICANDOIT_ISSUE_TITLE_999
  export PATH="${PATH_WITHOUT_GH}"
  cd "$FIXTURE_REPO"
  resolve_auto_branch_name 'fix issue 999 quickly' "$FIXTURE_REPO"
) >/tmp/aicandoit-auto-branch.err 2>&1
status_missing_gh=$?
set -e
[[ $status_missing_gh -ne 0 ]] || fail 'missing gh should fail issue metadata resolution'

set +e
(
  unset AICANDOIT_PR_TITLE_55
  export PATH="${PATH_WITHOUT_GH}"
  cd "$FIXTURE_REPO"
  resolve_auto_branch_name 'fix pr 55 quickly' "$FIXTURE_REPO"
) >/tmp/aicandoit-auto-branch.err 2>&1
status_missing_gh_pr=$?
set -e
[[ $status_missing_gh_pr -ne 0 ]] || fail 'missing gh should fail PR metadata resolution'

(
  cd "$FIXTURE_REPO"
  git checkout -q main
  export AICANDOIT_STUB_CODER_OUTPUT='feat/ai-generated-branch-name'
  PATH="${STUB_DIR}:$PATH" "$REPO_ROOT/bin/aicandoit" --coder codex --reviewer claude --auto-branch --mode plan 'implement issue 24 branch support'
)

end_to_end_branch="$(git -C "$FIXTURE_REPO" branch --show-current)"
assert_equals 'feat/ai-generated-branch-name' "$end_to_end_branch" 'end-to-end branch selection'
end_to_end_slug="$(branch_to_slug "$end_to_end_branch")"
[[ -f "${FIXTURE_REPO}/.aicandoit/branches/${end_to_end_slug}/plan.md" ]] || fail 'end-to-end plan artifact missing'
[[ -f "${FIXTURE_REPO}/.aicandoit/branches/${end_to_end_slug}/plan-review.md" ]] || fail 'end-to-end plan review artifact missing'

coder_prompt="$(cat "${AICANDOIT_STUB_CODER_PROMPT_FILE}")"
assert_contains "$coder_prompt" 'Return exactly one line containing only a git branch name in this format: <type>/<slug>' 'strict generation instruction'
assert_contains "$coder_prompt" $'RAW PROMPT:\nimplement issue 24 branch support' 'coder prompt includes raw prompt'

echo 'auto-branch helper tests passed'
