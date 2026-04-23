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

LAST_CMD=()
run_cli() {
  LAST_CMD=("$@")
}
build_log_file_path() {
  LOG_FILE_PATH="/tmp/test-aicandoit-dispatch.log"
}
run_cli_logged() {
  local _log_file="$1"
  shift
  run_cli "$@"
}

MODEL="dispatch-model"
PROMPT="implement feature"
CODER_MODEL="$MODEL"
PLANNER_MODEL="$MODEL"
REVIEWER_MODEL="$MODEL"
initialize_runtime_state

assert_planner_dispatch() {
  local cli="$1"
  PLANNER_CLI="$cli"

  run_plan
  case "$cli" in
    claude)
      assert_last_command "planner plan claude" claude --model "$MODEL" -p "/plan-it $PROMPT"
      ;;
    codex)
      assert_last_command "planner plan codex" codex --sandbox workspace-write -a never --model "$MODEL" exec "\$plan-it $PROMPT"
      ;;
    cursor)
      assert_last_command "planner plan cursor" cursor-agent --trust --print --model "$MODEL" "/plan-it $PROMPT"
      ;;
    gemini)
      assert_last_command "planner plan gemini" gemini --model "$MODEL" --prompt "/plan-it $PROMPT"
      ;;
  esac

  run_plan_update
  case "$cli" in
    claude)
      assert_last_command "planner plan-update claude" claude --model "$MODEL" -c -p "/plan-update"
      ;;
    codex)
      assert_last_command "planner plan-update codex" codex --sandbox workspace-write -a never --model "$MODEL" exec resume --last '$plan-update'
      ;;
    cursor)
      assert_last_command "planner plan-update cursor" cursor-agent --trust --print --model "$MODEL" --continue "/plan-update"
      ;;
    gemini)
      assert_last_command "planner plan-update gemini" gemini --model "$MODEL" --resume latest --prompt "/plan-update"
      ;;
  esac
}

assert_coder_dispatch() {
  local cli="$1"
  CODER_CLI="$cli"

  PLANNER_MATCHES_CODER=false
  run_code
  case "$cli" in
    claude)
      assert_last_command "coder code initial claude" claude --model "$MODEL" -p "/code-it"
      ;;
    codex)
      assert_last_command "coder code initial codex" codex --sandbox workspace-write -a never --model "$MODEL" exec '$code-it'
      ;;
    cursor)
      assert_last_command "coder code initial cursor" cursor-agent --trust --print --model "$MODEL" "/code-it"
      ;;
    gemini)
      assert_last_command "coder code initial gemini" gemini --model "$MODEL" --prompt "/code-it"
      ;;
  esac

  PLANNER_MATCHES_CODER=true
  run_code
  case "$cli" in
    claude)
      assert_last_command "coder code resume claude" claude --model "$MODEL" -c -p "/code-it"
      ;;
    codex)
      assert_last_command "coder code resume codex" codex --sandbox workspace-write -a never --model "$MODEL" exec resume --last '$code-it'
      ;;
    cursor)
      assert_last_command "coder code resume cursor" cursor-agent --trust --print --model "$MODEL" --continue "/code-it"
      ;;
    gemini)
      assert_last_command "coder code resume gemini" gemini --model "$MODEL" --resume latest --prompt "/code-it"
      ;;
  esac

  run_code_fix
  case "$cli" in
    claude)
      assert_last_command "coder code-fix claude" claude --model "$MODEL" -c -p "/code-fix"
      ;;
    codex)
      assert_last_command "coder code-fix codex" codex --sandbox workspace-write -a never --model "$MODEL" exec resume --last '$code-fix'
      ;;
    cursor)
      assert_last_command "coder code-fix cursor" cursor-agent --trust --print --model "$MODEL" --continue "/code-fix"
      ;;
    gemini)
      assert_last_command "coder code-fix gemini" gemini --model "$MODEL" --resume latest --prompt "/code-fix"
      ;;
  esac
}

assert_reviewer_dispatch() {
  local cli="$1"
  REVIEWER_CLI="$cli"

  run_plan_review
  case "$cli" in
    claude)
      assert_last_command "reviewer plan-review claude" claude --model "$MODEL" -p "/plan-review"
      ;;
    codex)
      assert_last_command "reviewer plan-review codex" codex --sandbox workspace-write -a never --model "$MODEL" exec '$plan-review'
      ;;
    cursor)
      assert_last_command "reviewer plan-review cursor" cursor-agent --trust --print --model "$MODEL" "/plan-review"
      ;;
    gemini)
      assert_last_command "reviewer plan-review gemini" gemini --model "$MODEL" --prompt "/plan-review"
      ;;
  esac

  run_plan_review_loop
  case "$cli" in
    claude)
      assert_last_command "reviewer plan-review-loop claude" claude --model "$MODEL" -c -p "/plan-review"
      ;;
    codex)
      assert_last_command "reviewer plan-review-loop codex" codex --sandbox workspace-write -a never --model "$MODEL" exec resume --last '$plan-review'
      ;;
    cursor)
      assert_last_command "reviewer plan-review-loop cursor" cursor-agent --trust --print --model "$MODEL" --continue "/plan-review"
      ;;
    gemini)
      assert_last_command "reviewer plan-review-loop gemini" gemini --model "$MODEL" --resume latest --prompt "/plan-review"
      ;;
  esac

  run_code_review
  case "$cli" in
    claude)
      assert_last_command "reviewer code-review claude" claude --model "$MODEL" -c -p "/code-review"
      ;;
    codex)
      assert_last_command "reviewer code-review codex" codex --sandbox workspace-write -a never --model "$MODEL" exec resume --last '$code-review'
      ;;
    cursor)
      assert_last_command "reviewer code-review cursor" cursor-agent --trust --print --model "$MODEL" --continue "/code-review"
      ;;
    gemini)
      assert_last_command "reviewer code-review gemini" gemini --model "$MODEL" --resume latest --prompt "/code-review"
      ;;
  esac

  run_code_review_loop
  case "$cli" in
    claude)
      assert_last_command "reviewer code-review-loop claude" claude --model "$MODEL" -c -p "/code-review"
      ;;
    codex)
      assert_last_command "reviewer code-review-loop codex" codex --sandbox workspace-write -a never --model "$MODEL" exec resume --last '$code-review'
      ;;
    cursor)
      assert_last_command "reviewer code-review-loop cursor" cursor-agent --trust --print --model "$MODEL" --continue "/code-review"
      ;;
    gemini)
      assert_last_command "reviewer code-review-loop gemini" gemini --model "$MODEL" --resume latest --prompt "/code-review"
      ;;
  esac
}

for cli in claude codex cursor gemini; do
  assert_planner_dispatch "$cli"
  assert_coder_dispatch "$cli"
  assert_reviewer_dispatch "$cli"
done

echo 'dispatch coverage tests passed'
