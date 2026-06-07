#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 --staged | --range [from-ref] [to-ref] | --all" >&2
  exit 1
}

if [ "$#" -eq 0 ]; then
  usage
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

mode="$1"
lint_cmd=()
policy_cmd=()
maintainability_cmd=()
coverage_cmd=()

case "$mode" in
  --staged)
    if [ "$#" -ne 1 ]; then
      usage
    fi
    lint_cmd=(scripts/lint_changed_dart.sh --staged)
    policy_cmd=(scripts/check_changed_dart_policy.sh --staged)
    maintainability_cmd=(python3 scripts/check_changed_dart_maintainability.py --staged)
    coverage_cmd=(python3 scripts/check_changed_dart_coverage.py --staged)
    ;;
  --range)
    if [ "$#" -ne 3 ]; then
      usage
    fi
    lint_cmd=(scripts/lint_changed_dart.sh --range "$2" "$3")
    policy_cmd=(scripts/check_changed_dart_policy.sh --range "$2" "$3")
    maintainability_cmd=(python3 scripts/check_changed_dart_maintainability.py --range "$2" "$3")
    coverage_cmd=(python3 scripts/check_changed_dart_coverage.py --range "$2" "$3")
    ;;
  --all)
    if [ "$#" -ne 1 ]; then
      usage
    fi
    lint_cmd=(flutter analyze)
    policy_cmd=(scripts/check_changed_dart_policy.sh --all)
    maintainability_cmd=(python3 scripts/check_changed_dart_maintainability.py --all)
    coverage_cmd=(python3 scripts/check_changed_dart_coverage.py --all)
    ;;
  *)
    usage
    ;;
esac

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/fast_ci.XXXXXX")
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

run_check() {
  local name="$1"
  shift
  local log_file="$tmp_dir/${name}.log"

  echo "[$name] starting"
  if "$@" >"$log_file" 2>&1; then
    echo "[$name] passed"
    return 0
  fi

  echo "[$name] failed"
  cat "$log_file"
  return 1
}

run_check_capture() {
  local name="$1"
  shift
  local log_file="$tmp_dir/${name}.log"

  if "$@" >"$log_file" 2>&1; then
    return 0
  fi

  return 1
}

echo "Running fast local checks in parallel:"
printf '  - %s\n' "lint/analyze" "ui policy" "maintainability"

run_check_capture lint "${lint_cmd[@]}" &
lint_pid=$!
run_check_capture policy "${policy_cmd[@]}" &
policy_pid=$!
run_check_capture maintainability "${maintainability_cmd[@]}" &
maintainability_pid=$!

parallel_failed=0
for entry in "lint:$lint_pid" "policy:$policy_pid" "maintainability:$maintainability_pid"; do
  name=${entry%%:*}
  pid=${entry#*:}

  if wait "$pid"; then
    echo "[$name] passed"
  else
    echo "[$name] failed"
    cat "$tmp_dir/${name}.log"
    parallel_failed=1
  fi
done

if [ "$parallel_failed" -ne 0 ]; then
  exit 1
fi

if run_check coverage "${coverage_cmd[@]}"; then
  echo "Fast local CI passed."
fi
