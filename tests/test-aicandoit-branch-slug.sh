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

# Assert that two strings differ.
assert_not_equals() {
  local left="$1"
  local right="$2"
  local label="$3"

  if [[ "$left" == "$right" ]]; then
    fail "$label unexpectedly matched '$left'"
  fi
}

slug_one="$(branch_to_slug 'feature/a_b')"
slug_two="$(branch_to_slug 'feature_a/b')"

assert_not_equals "$slug_one" "$slug_two" 'collision-safe slug'

slug_one_repeat="$(branch_to_slug 'feature/a_b')"
assert_equals "$slug_one" "$slug_one_repeat" 'deterministic slug'

[[ "$slug_one" =~ ^feature_a_b-[0-9a-f]{10}$ ]] || fail "slug pattern mismatch for feature/a_b: $slug_one"
[[ "$slug_two" =~ ^feature_a_b-[0-9a-f]{10}$ ]] || fail "slug pattern mismatch for feature_a/b: $slug_two"

echo 'branch slug helper tests passed'
