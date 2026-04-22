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

assert_file_contains() {
  local path="$1"
  local needle="$2"
  local label="$3"
  local content=""

  if [[ ! -f "$path" ]]; then
    fail "$label missing file '$path'"
  fi
  content="$(cat "$path")"
  assert_contains "$content" "$needle" "$label"
}

assert_file_exists() {
  local path="$1"
  local label="$2"

  if [[ ! -f "$path" ]]; then
    fail "$label missing file '$path'"
  fi
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
STUB_DIR="${TMP_DIR}/stubs"
mkdir -p "$STUB_DIR"

EMIT_SCRIPT="${STUB_DIR}/emit"
cat > "$EMIT_SCRIPT" <<'EOF'
#!/usr/bin/env bash
echo "stdout:$1"
echo "stderr:$1" >&2
EOF
chmod +x "$EMIT_SCRIPT"

QUIET_LOG="${TMP_DIR}/quiet.log"
VERBOSE_LOG="${TMP_DIR}/verbose.log"

VERBOSE=false
quiet_output="$(run_cli_logged "$QUIET_LOG" "$EMIT_SCRIPT" quiet)"
assert_equals "" "$quiet_output" "quiet mode suppresses console output"
assert_file_contains "$QUIET_LOG" "stdout:quiet" "quiet mode log captures stdout"
assert_file_contains "$QUIET_LOG" "stderr:quiet" "quiet mode log captures stderr"

VERBOSE=true
verbose_output="$(run_cli_logged "$VERBOSE_LOG" "$EMIT_SCRIPT" loud)"
assert_contains "$verbose_output" "stdout:loud" "verbose mode prints stdout"
assert_contains "$verbose_output" "stderr:loud" "verbose mode prints stderr"
assert_file_contains "$VERBOSE_LOG" "stdout:loud" "verbose mode log captures stdout"
assert_file_contains "$VERBOSE_LOG" "stderr:loud" "verbose mode log captures stderr"

ARTIFACT_ROOT="${TMP_DIR}/artifacts"
BRANCH="gh/15"
BRANCH_PATH="gh_15"
LOG_CONTEXT_READY=false
LOG_DIR=""
unset LOG_SEQUENCE_COUNTER
unset LOG_SEQUENCE_VALUE

build_log_file_path planner plan
path_one="$LOG_FILE_PATH"
build_log_file_path planner plan
path_two="$LOG_FILE_PATH"
assert_equals "${ARTIFACT_ROOT}/branches/${BRANCH_PATH}/logs/planner-plan-001.log" "$path_one" "first planner log path"
assert_equals "${ARTIFACT_ROOT}/branches/${BRANCH_PATH}/logs/planner-plan-002.log" "$path_two" "second planner log path"

CODER_MODEL=""
PLANNER_MODEL=""
REVIEWER_MODEL=""
initialize_runtime_state

run_cli() {
  echo "stdout:$*"
  echo "stderr:$*" >&2
}

PROMPT="ship logs"
PLANNER_CLI="claude"
REVIEWER_CLI="claude"

VERBOSE=false
run_role_action planner plan false >/dev/null
planner_log="${ARTIFACT_ROOT}/branches/${BRANCH_PATH}/logs/planner-plan-001.log"
assert_file_exists "$planner_log" "planner log exists"
assert_file_contains "$planner_log" "stdout:claude" "planner log stores command output"

REVIEW_LOOP_ATTEMPT=1
run_role_action reviewer code-review true >/dev/null
reviewer_log="${ARTIFACT_ROOT}/branches/${BRANCH_PATH}/logs/reviewer-code-review-loop-001.log"
assert_file_exists "$reviewer_log" "review loop log exists"
assert_file_contains "$reviewer_log" "stdout:claude" "review loop log stores command output"

review_file="${TMP_DIR}/code-review.md"
run_update_stub() {
  :
}
run_review_stub() {
  printf '%s\n' 'ALL GOOD' > "$review_file"
}

rm -f "$review_file"
review_loop "Code" "$review_file" run_update_stub run_review_stub "Coder" >/dev/null
assert_equals "0" "${REVIEW_LOOP_ATTEMPT}" "review loop resets attempt state"

run_role_action reviewer code-review false >/dev/null
initial_review_log="${ARTIFACT_ROOT}/branches/${BRANCH_PATH}/logs/reviewer-code-review-001.log"
assert_file_exists "$initial_review_log" "post-loop initial review log exists"

echo 'logging behavior tests passed'
