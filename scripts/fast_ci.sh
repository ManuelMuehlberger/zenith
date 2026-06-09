#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [--full-static] [--fresh-coverage] (--staged | --range [from-ref] [to-ref] | --all)" >&2
  exit 1
}

if [ "$#" -eq 0 ]; then
  usage
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

full_static=0
fresh_coverage=0
mode=""
lint_cmd=()
policy_cmd=()
maintainability_cmd=()
coverage_cmd=()
static_cmd=()
mode_args=()

collect_changed_paths() {
  case "$mode" in
    --staged)
      git diff --cached --name-only --diff-filter=ACMR
      ;;
    --range)
      git diff --name-only --diff-filter=ACMR "${mode_args[0]}" "${mode_args[1]}"
      ;;
    --all)
      find lib test -type f
      printf '%s\n' analysis_options.yaml pubspec.yaml pubspec.lock
      ;;
  esac
}

has_matching_change() {
  local pattern="$1"
  while IFS= read -r path; do
    if [[ "$path" == $pattern ]]; then
      return 0
    fi
  done < <(collect_changed_paths)
  return 1
}

needs_pub_get() {
  has_matching_change 'pubspec.yaml' || has_matching_change 'pubspec.lock'
}

needs_full_static() {
  [ "$full_static" -eq 1 ] || return 1
  has_matching_change '*.dart' ||
    has_matching_change 'analysis_options.yaml' ||
    has_matching_change 'pubspec.yaml' ||
    has_matching_change 'pubspec.lock'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --full-static)
      full_static=1
      shift
      ;;
    --fresh-coverage)
      fresh_coverage=1
      shift
      ;;
    --staged|--range|--all)
      mode="$1"
      shift
      break
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "$mode" ]; then
  usage
fi

case "$mode" in
  --staged)
    if [ "$#" -ne 0 ]; then
      usage
    fi
    mode_args=()
    lint_cmd=(scripts/lint_changed_dart.sh --staged)
    policy_cmd=(scripts/check_changed_dart_policy.sh --staged)
    maintainability_cmd=(python3 scripts/check_changed_dart_maintainability.py --staged)
    coverage_cmd=(python3 scripts/check_changed_dart_coverage.py --staged)
    ;;
  --range)
    if [ "$#" -ne 2 ]; then
      usage
    fi
    mode_args=("$1" "$2")
    lint_cmd=(scripts/lint_changed_dart.sh --range "$1" "$2")
    policy_cmd=(scripts/check_changed_dart_policy.sh --range "$1" "$2")
    maintainability_cmd=(python3 scripts/check_changed_dart_maintainability.py --range "$1" "$2")
    coverage_cmd=(python3 scripts/check_changed_dart_coverage.py --range "$1" "$2")
    ;;
  --all)
    if [ "$#" -ne 0 ]; then
      usage
    fi
    mode_args=()
    lint_cmd=(flutter analyze)
    policy_cmd=(scripts/check_changed_dart_policy.sh --all)
    maintainability_cmd=(python3 scripts/check_changed_dart_maintainability.py --all)
    coverage_cmd=(python3 scripts/check_changed_dart_coverage.py --all)
    ;;
  *)
    usage
    ;;
esac

if needs_pub_get; then
  echo "[pub-get] pubspec changed; refreshing dependencies"
  flutter pub get
fi

if needs_full_static; then
  static_cmd=(scripts/run_full_static_checks.sh)
  echo "Running fast local checks in parallel:"
  printf '  - %s\n' "full static" "ui policy" "maintainability"
else
  echo "Running fast local checks in parallel:"
  printf '  - %s\n' "lint/analyze" "ui policy" "maintainability"
fi

if [ "$fresh_coverage" -eq 1 ]; then
  coverage_cmd=(env ZENITH_DISABLE_COVERAGE_CACHE=1 "${coverage_cmd[@]}")
fi

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

if [ "${#static_cmd[@]}" -gt 0 ]; then
  run_check_capture static "${static_cmd[@]}" &
  static_pid=$!
else
  run_check_capture lint "${lint_cmd[@]}" &
  lint_pid=$!
fi
run_check_capture policy "${policy_cmd[@]}" &
policy_pid=$!
run_check_capture maintainability "${maintainability_cmd[@]}" &
maintainability_pid=$!

parallel_failed=0
entries=("policy:$policy_pid" "maintainability:$maintainability_pid")
if [ "${#static_cmd[@]}" -gt 0 ]; then
  entries=("static:$static_pid" "${entries[@]}")
else
  entries=("lint:$lint_pid" "${entries[@]}")
fi

for entry in "${entries[@]}"; do
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

run_check coverage "${coverage_cmd[@]}"
echo "Fast local CI passed."
