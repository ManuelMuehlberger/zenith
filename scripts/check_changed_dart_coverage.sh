#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 --staged | --range [from-ref] [to-ref] | --all [--min percent]" >&2
  exit 1
}

if [ "$#" -eq 0 ]; then
  usage
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

changed_files=()
files_to_check=()
scan_mode=""
range_from=""
range_to=""
min_coverage="${ZENITH_MIN_CHANGED_FILE_COVERAGE:-80}"
coverage_exceptions=(
  "lib/models/typedefs.dart"
  "lib/services/insights/insight_data_provider.dart"
)

collect_changed_files() {
  while IFS= read -r file_path; do
    if [ -n "$file_path" ]; then
      changed_files+=("$file_path")
    fi
  done
}

is_frontend_file() {
  local file_path="$1"

  case "$file_path" in
    lib/screens/*|lib/widgets/*|lib/theme/*|lib/main.dart)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_coverage_exception() {
  local file_path="$1"
  local exception_path

  for exception_path in "${coverage_exceptions[@]}"; do
    if [ "$file_path" = "$exception_path" ]; then
      return 0
    fi
  done

  return 1
}

validate_min_coverage() {
  case "$min_coverage" in
    ''|*[!0-9.]*)
      echo "Coverage threshold must be numeric, got: $min_coverage" >&2
      exit 1
      ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --staged)
      if [ -n "$scan_mode" ]; then
        usage
      fi
      scan_mode="staged"
      shift
      ;;
    --range)
      if [ -n "$scan_mode" ] || [ "$#" -lt 3 ]; then
        usage
      fi
      scan_mode="range"
      range_from="$2"
      range_to="$3"
      shift 3
      ;;
    --all)
      if [ -n "$scan_mode" ]; then
        usage
      fi
      scan_mode="all"
      shift
      ;;
    --min)
      if [ "$#" -lt 2 ]; then
        usage
      fi
      min_coverage="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "$scan_mode" ]; then
  usage
fi

validate_min_coverage

case "$scan_mode" in
  staged)
    collect_changed_files < <(
      git diff --cached --name-only --diff-filter=ACMR -- '*.dart'
    )
    ;;
  range)
    collect_changed_files < <(
      git diff --name-only --diff-filter=ACMR "$range_from" "$range_to" -- '*.dart'
    )
    ;;
  all)
    collect_changed_files < <(find lib -name '*.dart' -type f | sort)
    ;;
esac

for file_path in "${changed_files[@]}"; do
  if [[ "$file_path" != lib/*.dart ]]; then
    continue
  fi

  if is_frontend_file "$file_path"; then
    continue
  fi

  if is_coverage_exception "$file_path"; then
    continue
  fi

  files_to_check+=("$file_path")
done

if [ "${#files_to_check[@]}" -eq 0 ]; then
  echo "No changed non-frontend Dart files require coverage enforcement."
  exit 0
fi

echo "Checking changed non-frontend Dart files for minimum coverage (${min_coverage}%):"
printf '  %s\n' "${files_to_check[@]}"

flutter test --coverage >/dev/null

if [ ! -f coverage/lcov.info ]; then
  echo "coverage/lcov.info was not generated." >&2
  exit 1
fi

failure_count=0

for file_path in "${files_to_check[@]}"; do
  coverage_record=$(awk -F: -v target="$file_path" '
    /^SF:/ {
      current = $2
      next
    }
    current == target && /^LF:/ {
      found = $2 + 0
      next
    }
    current == target && /^LH:/ {
      hit = $2 + 0
      next
    }
    current == target && /^end_of_record$/ {
      printf "%d\t%d\n", hit, found
      exit
    }
  ' coverage/lcov.info)

  if [ -n "$coverage_record" ]; then
    IFS=$'\t' read -r hit found <<EOF
$coverage_record
EOF
  else
    hit=""
    found=""
  fi

  if [ -z "$hit" ] || [ -z "$found" ]; then
    echo "FAIL: $file_path is missing from coverage/lcov.info. Add or update tests that exercise it."
    failure_count=$((failure_count + 1))
    continue
  fi

  if [ "$found" -eq 0 ]; then
    echo "SKIP: $file_path has no executable lines in coverage output."
    continue
  fi

  percent=$(awk -v hit="$hit" -v found="$found" 'BEGIN { printf "%.2f", (100 * hit / found) }')
  meets_threshold=$(awk -v percent="$percent" -v min="$min_coverage" 'BEGIN { print (percent + 0 >= min + 0) ? 1 : 0 }')

  if [ "$meets_threshold" -eq 1 ]; then
    echo "PASS: $file_path coverage ${percent}% ($hit/$found)"
  else
    echo "FAIL: $file_path coverage ${percent}% ($hit/$found) is below ${min_coverage}%"
    failure_count=$((failure_count + 1))
  fi
done

if [ "$failure_count" -gt 0 ]; then
  echo "Coverage enforcement failures: $failure_count"
  exit 1
fi

echo "All changed non-frontend Dart files meet the coverage threshold."