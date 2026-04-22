#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=bin/aicandoit
source "${REPO_ROOT}/bin/aicandoit"

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

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"

  if [[ "$haystack" != *"$needle"* ]]; then
    fail "$label missing '$needle' in '$haystack'"
  fi
}

assert_last_command() {
  local label="$1"
  shift
  local -a expected=("$@")

  if [[ ${#LAST_CMD[@]} -ne ${#expected[@]} ]]; then
    fail "$label expected ${#expected[@]} args but got ${#LAST_CMD[@]}"
  fi

  local i
  for i in "${!expected[@]}"; do
    if [[ "${LAST_CMD[$i]}" != "${expected[$i]}" ]]; then
      fail "$label arg[$i] expected '${expected[$i]}' but got '${LAST_CMD[$i]}'"
    fi
  done
}

assert_validate_success() {
  local coder="$1"
  local planner="$2"
  local reviewer="$3"
  local label="$4"

  if ! (
    set -euo pipefail
    CODER="$coder"
    PLANNER="$planner"
    REVIEWER="$reviewer"
    BRANCH=""
    USE_CURRENT_BRANCH=true
    AUTO_BRANCH=false
    MODE="plan"
    MODE_SET=true
    USE_WORKTREE=false
    PROMPT="test prompt"
    validate_args
  ); then
    fail "$label should pass validate_args"
  fi
}

assert_validate_failure() {
  local coder="$1"
  local planner="$2"
  local reviewer="$3"
  local expected_fragment="$4"
  local label="$5"
  local output=""
  local status=0

  set +e
  output="$(
    (
      set -euo pipefail
      CODER="$coder"
      PLANNER="$planner"
      REVIEWER="$reviewer"
      BRANCH=""
      USE_CURRENT_BRANCH=true
      AUTO_BRANCH=false
      MODE="plan"
      MODE_SET=true
      USE_WORKTREE=false
      PROMPT="test prompt"
      validate_args
    ) 2>&1
  )"
  status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    fail "$label should fail validate_args"
  fi
  assert_contains "$output" "$expected_fragment" "$label"
}

LAST_CMD=()
run_cli() {
  LAST_CMD=("$@")
}

assert_validate_success "gemini" "" "claude" "accept coder gemini reviewer claude"
assert_validate_success "codex" "gemini" "cursor" "accept planner gemini"
assert_validate_success "gemini/model-a" "" "gemini/model-b" "accept gemini reviewer with different model"
assert_validate_failure "gemini/model-a" "" "gemini/model-a" "coder and reviewer must differ" "reject same coder and reviewer gemini model"
assert_validate_failure "codex" "gemini/model-a" "gemini/model-a" "planner and reviewer must differ" "reject same planner and reviewer gemini model"

assert_mode_prerequisite_success() {
  local mode="$1"
  local plan_exists="$2"
  local code_exists="$3"
  local label="$4"
  local tmp_dir=""

  tmp_dir="$(mktemp -d)"
  if [[ "$plan_exists" == "yes" ]]; then
    touch "${tmp_dir}/plan.md"
  fi
  if [[ "$code_exists" == "yes" ]]; then
    touch "${tmp_dir}/code-review.md"
  fi

  if ! (
    set -euo pipefail
    MODE="$mode"
    PLAN_PATH="${tmp_dir}/plan.md"
    CODE_FILE="${tmp_dir}/code-review.md"
    validate_mode_prerequisites
  ); then
    rm -rf "$tmp_dir"
    fail "$label should pass validate_mode_prerequisites"
  fi

  rm -rf "$tmp_dir"
}

assert_mode_prerequisite_failure() {
  local mode="$1"
  local plan_exists="$2"
  local code_exists="$3"
  local expected_fragment="$4"
  local label="$5"
  local tmp_dir=""
  local output=""
  local status=0

  tmp_dir="$(mktemp -d)"
  if [[ "$plan_exists" == "yes" ]]; then
    touch "${tmp_dir}/plan.md"
  fi
  if [[ "$code_exists" == "yes" ]]; then
    touch "${tmp_dir}/code-review.md"
  fi

  set +e
  output="$(
    (
      set -euo pipefail
      MODE="$mode"
      PLAN_PATH="${tmp_dir}/plan.md"
      CODE_FILE="${tmp_dir}/code-review.md"
      validate_mode_prerequisites
    ) 2>&1
  )"
  status=$?
  set -e

  rm -rf "$tmp_dir"

  if [[ "$status" -eq 0 ]]; then
    fail "$label should fail validate_mode_prerequisites"
  fi
  assert_contains "$output" "$expected_fragment" "$label"
}

assert_mode_prerequisite_failure "plan-review" "no" "no" "requires an existing plan" "plan-review requires plan artifact"
assert_mode_prerequisite_failure "code" "no" "no" "requires an approved plan" "code requires plan artifact"
assert_mode_prerequisite_success "code-review" "no" "no" "code-review allows missing review artifact"
assert_mode_prerequisite_success "code-review" "yes" "yes" "code-review works with existing review artifact"

CODER_MODEL="gemini-model"
PLANNER_MODEL="gemini-model"
REVIEWER_MODEL="gemini-model"
initialize_runtime_state

PROMPT="implement feature"
PLANNER_CLI="gemini"
run_plan
assert_last_command "run_plan gemini" gemini --model gemini-model --prompt "/plan-it implement feature"

PLANNER_MODEL=""
initialize_runtime_state
PLANNER_CLI="gemini"
run_plan_update
assert_last_command "run_plan_update gemini" gemini --resume latest --prompt "/plan-update"

CODER_MODEL="gemini-model"
initialize_runtime_state
CODER_CLI="gemini"
PLANNER_MATCHES_CODER=true
run_code
assert_last_command "run_code gemini resume" gemini --model gemini-model --resume latest --prompt "/code-it"

PLANNER_MATCHES_CODER=false
run_code
assert_last_command "run_code gemini initial" gemini --model gemini-model --prompt "/code-it"

run_code_fix
assert_last_command "run_code_fix gemini" gemini --model gemini-model --resume latest --prompt "/code-fix"

REVIEWER_MODEL=""
initialize_runtime_state
REVIEWER_CLI="gemini"
run_plan_review
assert_last_command "run_plan_review gemini" gemini --prompt "/plan-review"

run_plan_review_loop
assert_last_command "run_plan_review_loop gemini" gemini --resume latest --prompt "/plan-review"

run_code_review
assert_last_command "run_code_review gemini" gemini --resume latest --prompt "/code-review"

run_code_review_loop
assert_last_command "run_code_review_loop gemini" gemini --resume latest --prompt "/code-review"

BOOTSTRAP_TMP_DIR="$(mktemp -d)"
BOOTSTRAP_CALLS=0
REVIEW_LOOP_CALLS=0
REVIEW_LOOP_ARGS=()
run_code_review() {
  BOOTSTRAP_CALLS=$((BOOTSTRAP_CALLS + 1))
}
review_loop() {
  REVIEW_LOOP_CALLS=$((REVIEW_LOOP_CALLS + 1))
  REVIEW_LOOP_ARGS=("$@")
}

MODE="code-review"
CODE_FILE="${BOOTSTRAP_TMP_DIR}/code-review.md"

run_selected_mode >/dev/null
assert_equals "1" "$BOOTSTRAP_CALLS" "code-review missing artifact triggers bootstrap review"
assert_equals "1" "$REVIEW_LOOP_CALLS" "code-review missing artifact still enters review loop"
assert_equals "Code" "${REVIEW_LOOP_ARGS[0]}" "code-review loop label"
assert_equals "$CODE_FILE" "${REVIEW_LOOP_ARGS[1]}" "code-review loop artifact path"
assert_equals "run_code_fix" "${REVIEW_LOOP_ARGS[2]}" "code-review loop fix callback"
assert_equals "run_code_review_loop" "${REVIEW_LOOP_ARGS[3]}" "code-review loop review callback"
assert_equals "Coder" "${REVIEW_LOOP_ARGS[4]}" "code-review loop agent label"

touch "$CODE_FILE"
BOOTSTRAP_CALLS=0
REVIEW_LOOP_CALLS=0
REVIEW_LOOP_ARGS=()
run_selected_mode >/dev/null
assert_equals "0" "$BOOTSTRAP_CALLS" "code-review existing artifact skips bootstrap review"
assert_equals "1" "$REVIEW_LOOP_CALLS" "code-review existing artifact still enters review loop"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR" "$BOOTSTRAP_TMP_DIR"' EXIT
STUB_DIR="${TMP_DIR}/stubs"
mkdir -p "$STUB_DIR"

for cmd in git gh claude codex cursor-agent; do
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "${STUB_DIR}/${cmd}"
  chmod +x "${STUB_DIR}/${cmd}"
done

set +e
dep_output="$(
  (
    set -euo pipefail
    PATH="$STUB_DIR"
    CODER_CLI="gemini"
    PLANNER_CLI="codex"
    REVIEWER_CLI="claude"
    check_dependencies
  ) 2>&1
)"
dep_status=$?
set -e

assert_equals "127" "$dep_status" "missing gemini dependency exit code"
assert_contains "$dep_output" "gemini not found in PATH" "missing gemini dependency output"

echo 'gemini coverage tests passed'
