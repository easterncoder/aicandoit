#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

fail() {
  echo "error: $1" >&2
  exit 1
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local label="$3"

  if [[ "$expected" != "$actual" ]]; then
    fail "$label expected '$expected' but got '$actual'"
  fi
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FIXTURE_REPO="${TMP_DIR}/repo"
git init -q -b main "$FIXTURE_REPO"
git -C "$FIXTURE_REPO" config user.name "Fixture User"
git -C "$FIXTURE_REPO" config user.email "fixture@example.com"

printf 'initial\n' > "${FIXTURE_REPO}/README.md"
git -C "$FIXTURE_REPO" add README.md
git -C "$FIXTURE_REPO" commit -qm 'chore: initialize fixture'
git -C "$FIXTURE_REPO" checkout -qb 'feature/test-loop'

STUB_DIR="${TMP_DIR}/stubs"
mkdir -p "$STUB_DIR"

printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "${STUB_DIR}/gh"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'branch="$(git branch --show-current)"' \
  'slug="${branch//\//_}"' \
  'mkdir -p ".aicandoit/branches/${slug}"' \
  'printf "Template target: `.aicandoit/branches/{branch-slug}/plan.md`\n" > ".aicandoit/branches/${slug}/plan.md"' \
  'exit 0' > "${STUB_DIR}/codex"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'branch="$(git branch --show-current)"' \
  'slug="${branch//\//_}"' \
  'mkdir -p ".aicandoit/branches/${slug}"' \
  'printf "ALL GOOD\n" > ".aicandoit/branches/${slug}/plan-review.md"' \
  'printf "ALL GOOD\n" > ".aicandoit/branches/${slug}/code-review.md"' \
  'exit 0' > "${STUB_DIR}/claude"
chmod +x "${STUB_DIR}/gh" "${STUB_DIR}/codex" "${STUB_DIR}/claude"

(
  cd "$FIXTURE_REPO"
  PATH="${STUB_DIR}:$PATH" MAX_TRIES=2 SLEEP_SECS=0 \
    "$REPO_ROOT/bin/aicandoit" --coder codex --reviewer claude --current-branch 'legacy loop repro'
)

assert_equals 'feature/test-loop' "$(git -C "$FIXTURE_REPO" branch --show-current)" 'branch remains checked out'
[[ -f "${FIXTURE_REPO}/.aicandoit/branches/feature_test-loop/plan.md" ]] || fail 'legacy plan missing'
[[ -f "${FIXTURE_REPO}/.aicandoit/branches/feature_test-loop/plan-review.md" ]] || fail 'legacy plan review missing'
[[ -f "${FIXTURE_REPO}/.aicandoit/branches/feature_test-loop/code-review.md" ]] || fail 'legacy code review missing'

echo 'review loop legacy path test passed'
