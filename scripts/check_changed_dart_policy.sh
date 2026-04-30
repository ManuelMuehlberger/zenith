#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 --staged | --range [from-ref] [to-ref]" >&2
  exit 1
}

if [ "$#" -eq 0 ]; then
  usage
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

changed_files=()
color_allowlist=(
  "lib/main.dart"
  "lib/constants/app_constants.dart"
)

collect_changed_files() {
  while IFS= read -r file_path; do
    if [ -n "$file_path" ]; then
      changed_files+=("$file_path")
    fi
  done
}

is_color_allowlisted() {
  local file_path="$1"

  for allowed_path in "${color_allowlist[@]}"; do
    if [ "$file_path" = "$allowed_path" ]; then
      return 0
    fi
  done

  return 1
}

report_matches() {
  local severity="$1"
  local heading="$2"
  local file_path="$3"
  local matches="$4"

  echo "$severity: $heading"
  echo "  $file_path"
  while IFS= read -r match_line; do
    if [ -n "$match_line" ]; then
      echo "    $match_line"
    fi
  done <<< "$matches"
}

case "$1" in
  --staged)
    shift
    collect_changed_files < <(
      git diff --cached --name-only --diff-filter=ACMR -- '*.dart'
    )
    ;;
  --range)
    if [ "$#" -ne 3 ]; then
      usage
    fi
    collect_changed_files < <(
      git diff --name-only --diff-filter=ACMR "$2" "$3" -- '*.dart'
    )
    ;;
  *)
    usage
    ;;
esac

if [ "${#changed_files[@]}" -eq 0 ]; then
  echo "No changed Dart files to check for policy violations."
  exit 0
fi

echo "Checking changed Dart files for UI policy violations:"
printf '  %s\n' "${changed_files[@]}"

error_count=0
warning_count=0

for file_path in "${changed_files[@]}"; do
  if [[ "$file_path" != lib/*.dart ]]; then
    continue
  fi

  with_opacity_matches=$(grep -nE '\.withOpacity\(' "$file_path" || true)
  if [ -n "$with_opacity_matches" ]; then
    report_matches \
      "ERROR" \
      "Deprecated color API usage; replace with withValues(alpha: ...)" \
      "$file_path" \
      "$with_opacity_matches"
    error_count=$((error_count + 1))
  fi

  if ! is_color_allowlisted "$file_path"; then
    raw_color_matches=$(grep -nE '\b(Colors|CupertinoColors)\.' "$file_path" || true)
    if [ -n "$raw_color_matches" ]; then
      report_matches \
        "ERROR" \
        "Raw framework color usage is only allowed in the theme/token files" \
        "$file_path" \
        "$raw_color_matches"
      error_count=$((error_count + 1))
    fi
  fi

  inline_text_matches=$(grep -nE "Text\(\s*(const\s+)?['\"]|label:\s*['\"]|placeholder:\s*['\"]|semanticLabel:\s*['\"]|tooltip:\s*['\"]" "$file_path" || true)
  if [ -n "$inline_text_matches" ]; then
    report_matches \
      "WARNING" \
      "Likely inline user-facing strings; prefer centralizing strings in the next refactor" \
      "$file_path" \
      "$inline_text_matches"
    warning_count=$((warning_count + 1))
  fi

  text_style_color_matches=$(grep -nE 'TextStyle\(.*color:\s*(Colors|CupertinoColors)\.' "$file_path" || true)
  if [ -n "$text_style_color_matches" ]; then
    report_matches \
      "WARNING" \
      "TextStyle uses a raw framework color on the same line; prefer theme tokens" \
      "$file_path" \
      "$text_style_color_matches"
    warning_count=$((warning_count + 1))
  fi
done

if [ "$warning_count" -gt 0 ]; then
  echo "Policy warnings: $warning_count"
fi

if [ "$error_count" -gt 0 ]; then
  echo "Policy errors: $error_count"
  exit 1
fi

echo "No blocking UI policy violations found."