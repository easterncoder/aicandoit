#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=bin/aicandoit
source "${REPO_ROOT}/bin/aicandoit"

FIXED_TIMESTAMP="20260423000000"
generate_run_timestamp_utc() {
  printf '%s\n' "$FIXED_TIMESTAMP"
}

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
LOG_CONTEXT_READY=false
LOG_DIR=""
LOG_RUN_DIR=""
RUN_TIMESTAMP_UTC=""
RUN_COUNTER=""
unset LOG_SEQUENCE_COUNTER
unset LOG_SEQUENCE_VALUE

resolved_branch_path="$(resolve_branch_artifact_slug "$BRANCH" "$ARTIFACT_ROOT")"
build_log_file_path planner plan
path_one="$LOG_FILE_PATH"
build_log_file_path planner plan
path_two="$LOG_FILE_PATH"
assert_equals "${ARTIFACT_ROOT}/branches/${resolved_branch_path}/logs/${FIXED_TIMESTAMP}-01/planner-plan-001.log" "$path_one" "first planner log path"
assert_equals "${ARTIFACT_ROOT}/branches/${resolved_branch_path}/logs/${FIXED_TIMESTAMP}-01/planner-plan-002.log" "$path_two" "second planner log path"

unset ARTIFACT_ROOT
DEFAULT_ROOT_TEST_SUFFIX="${RANDOM}"
BRANCH="feature/default-root-logging-test-${DEFAULT_ROOT_TEST_SUFFIX}"
LOG_CONTEXT_READY=false
LOG_DIR=""
LOG_RUN_DIR=""
RUN_TIMESTAMP_UTC=""
RUN_COUNTER=""
unset LOG_SEQUENCE_COUNTER
unset LOG_SEQUENCE_VALUE

resolved_default_branch_path_for_logs="$(resolve_branch_artifact_slug "$BRANCH" "$ARTIFACT_ROOT_DEFAULT")"
build_log_file_path planner plan
default_path_one="$LOG_FILE_PATH"
assert_equals "${ARTIFACT_ROOT_DEFAULT}/branches/${resolved_default_branch_path_for_logs}/logs/${FIXED_TIMESTAMP}-01/planner-plan-001.log" "$default_path_one" "default root first planner log path"

ARTIFACT_ROOT="${TMP_DIR}/artifacts"
BRANCH="gh/16"
resolved_collision_branch_path="$(resolve_branch_artifact_slug "$BRANCH" "$ARTIFACT_ROOT")"
mkdir -p "${ARTIFACT_ROOT}/branches/${resolved_collision_branch_path}/logs/${FIXED_TIMESTAMP}-01"
LOG_CONTEXT_READY=false
LOG_DIR=""
LOG_RUN_DIR=""
RUN_TIMESTAMP_UTC=""
RUN_COUNTER=""
unset LOG_SEQUENCE_COUNTER
unset LOG_SEQUENCE_VALUE

build_log_file_path planner plan
collision_path="$LOG_FILE_PATH"
assert_equals "${ARTIFACT_ROOT}/branches/${resolved_collision_branch_path}/logs/${FIXED_TIMESTAMP}-02/planner-plan-001.log" "$collision_path" "collision increments run folder counter"

ARTIFACT_ROOT="${TMP_DIR}/artifacts"
BRANCH="gh/18"
BRANCH_PATH="$(resolve_branch_artifact_slug "$BRANCH" "$ARTIFACT_ROOT")"
mkdir_race_injected=false
mkdir() {
  local target="${@: -1}"
  local race_target="${ARTIFACT_ROOT}/branches/${BRANCH_PATH}/logs/${FIXED_TIMESTAMP}-01"

  if [[ "$mkdir_race_injected" == false && "$#" -eq 1 && "$target" == "$race_target" ]]; then
    command mkdir -p "$target"
    mkdir_race_injected=true
    return 1
  fi

  command mkdir "$@"
}
LOG_CONTEXT_READY=false
LOG_DIR=""
LOG_RUN_DIR=""
RUN_TIMESTAMP_UTC=""
RUN_COUNTER=""
unset LOG_SEQUENCE_COUNTER
unset LOG_SEQUENCE_VALUE

build_log_file_path planner plan
race_path="$LOG_FILE_PATH"
assert_equals "${ARTIFACT_ROOT}/branches/${BRANCH_PATH}/logs/${FIXED_TIMESTAMP}-02/planner-plan-001.log" "$race_path" "atomic run folder claim skips race-created counter"
unset -f mkdir

unset ARTIFACT_ROOT
resolve_artifact_paths
resolved_default_branch_path="$(resolve_branch_artifact_slug "$BRANCH" "$ARTIFACT_ROOT_DEFAULT")"
assert_equals "${ARTIFACT_ROOT_DEFAULT}/branches/${resolved_default_branch_path}/plan.md" "$PLAN_PATH" "default root plan path"
assert_equals "${ARTIFACT_ROOT_DEFAULT}/branches/${resolved_default_branch_path}/code-review.md" "$CODE_FILE" "default root code review path"

# Restore override-backed state for subsequent log assertions.
ARTIFACT_ROOT="${TMP_DIR}/artifacts"
BRANCH="gh/17"
LOG_CONTEXT_READY=false
LOG_DIR=""
LOG_RUN_DIR=""
RUN_TIMESTAMP_UTC=""
RUN_COUNTER=""
unset LOG_SEQUENCE_COUNTER
unset LOG_SEQUENCE_VALUE

CODER_MODEL=""
PLANNER_MODEL=""
REVIEWER_MODEL=""
initialize_runtime_state
resolved_role_branch_path="$(resolve_branch_artifact_slug "$BRANCH" "$ARTIFACT_ROOT")"

run_cli() {
  echo "stdout:$*"
  echo "stderr:$*" >&2
}

PROMPT="ship logs"
PLANNER_CLI="claude"
REVIEWER_CLI="claude"

VERBOSE=false
run_role_action planner plan false >/dev/null
planner_log="${ARTIFACT_ROOT}/branches/${resolved_role_branch_path}/logs/${FIXED_TIMESTAMP}-01/planner-plan-001.log"
assert_file_exists "$planner_log" "planner log exists"
assert_file_contains "$planner_log" "stdout:claude" "planner log stores command output"

REVIEW_LOOP_ATTEMPT=1
run_role_action reviewer code-review true >/dev/null
reviewer_log="${ARTIFACT_ROOT}/branches/${resolved_role_branch_path}/logs/${FIXED_TIMESTAMP}-01/reviewer-code-review-loop-001.log"
assert_file_exists "$reviewer_log" "review loop log exists"
assert_file_contains "$reviewer_log" "stdout:claude" "review loop log stores command output"
assert_equals "$(dirname "$planner_log")" "$(dirname "$reviewer_log")" "one invocation shares run folder"

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
initial_review_log="${ARTIFACT_ROOT}/branches/${resolved_role_branch_path}/logs/${FIXED_TIMESTAMP}-01/reviewer-code-review-001.log"
assert_file_exists "$initial_review_log" "post-loop initial review log exists"

ARTIFACT_ROOT="${TMP_DIR}/artifacts"
BRANCH="feature/legacy-compat-logging"
legacy_branch_path="$(legacy_branch_to_slug "$BRANCH")"
hashed_branch_path="$(branch_to_slug "$BRANCH")"
mkdir -p "${ARTIFACT_ROOT}/branches/${legacy_branch_path}"
printf '%s\n' 'legacy plan' > "${ARTIFACT_ROOT}/branches/${legacy_branch_path}/plan.md"
mkdir -p "${ARTIFACT_ROOT}/branches/${hashed_branch_path}"
BRANCH_PATH="$hashed_branch_path"
LOG_CONTEXT_READY=false
LOG_DIR=""
LOG_RUN_DIR=""
RUN_TIMESTAMP_UTC=""
RUN_COUNTER=""
unset LOG_SEQUENCE_COUNTER
unset LOG_SEQUENCE_VALUE

build_log_file_path planner plan
legacy_compat_log_path="$LOG_FILE_PATH"
assert_equals "${ARTIFACT_ROOT}/branches/${legacy_branch_path}/logs/${FIXED_TIMESTAMP}-01/planner-plan-001.log" "$legacy_compat_log_path" "logging follows resolved legacy artifact path"
if [[ -d "${ARTIFACT_ROOT}/branches/${hashed_branch_path}/logs/${FIXED_TIMESTAMP}-01" ]]; then
  fail "logging should not create hashed logs-only run directory when legacy path is selected"
fi

echo 'logging behavior tests passed'
